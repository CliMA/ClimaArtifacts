#!/bin/bash

# This script is largely based off of `run_water_conservation_exp.sh` in
# `water_conservation_test`.

# This script checks out a specific commit of the ClimaLand.jl GitHub
# repository, and uses it to run the snowy land simulation which is running
# `ClimaLand.jl/experiments/long_runs/snowy_land.jl`. After the simulation
# is completed, the script prints the file path of the diagnostics in the
# terminal. This is the argument to `create_artifacts.jl`. Note that this
# script requires juliaup to be installed.

# Inform the user that the script requires one input argument, if it is not
# provided
[[ $# -lt 2 ]] && echo "Error! Usage: $0 <sim_dir> <true/false>" && exit 0

output_dir=$1
use_cuda=$2

# Validate the second argument is true or false
if ! [[("$use_cuda" == "true") || ("$use_cuda" == "false")]]; then
echo "The second argument can only be true or false"
exit 0
fi

# Parse the input argument for the output directory
mkdir -p $output_dir

# Go into newly created directory
cd $output_dir

# Clone the ClimaLand.jl repository
git clone https://github.com/CliMA/ClimaLand.jl.git
cd ClimaLand.jl

# Checkout the commit that was used to create the spun up soil initial
# conditions
git -c advice.detachedHEAD=false checkout 797a9b78253c61e9973d1808877145ef5c301155

# Use the same version of Julia that the long run was done on
juliaup add 1.11.3
julia +1.11.3 --project -e 'using Pkg; Pkg.instantiate(;verbose=true)'
julia +1.11.3 --project -e 'using Pkg; Pkg.status()'
julia +1.11.3 --project=.buildkite -e 'using Pkg; Pkg.instantiate(;verbose=true)'
julia +1.11.3 --project=.buildkite -e 'using Pkg; Pkg.precompile()'

if "$use_cuda" == "true"
then
echo "Using CUDA"
export CLIMACOMMS_DEVICE="CUDA"
julia +1.11.3 --project=.buildkite -e 'using CUDA; CUDA.precompile_runtime()'
fi

julia +1.11.3 --project=.buildkite -e 'using Pkg; Pkg.status()'

echo "Running snowy land simulation, this might take a while"
julia +1.11.3 --color=yes --project=.buildkite experiments/long_runs/snowy_land.jl

# Print the output_active directory by finding the symbolic link and print the
# absolute path
echo "Copy the file path below and use it as the input for create_artifacts.jl:"
find . -type l -ls | head -n 1 | awk '{print $11}' | xargs readlink -f
