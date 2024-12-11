#!/bin/bash

# This script checks out a specific commit of the ClimaLand.jl GitHub
# repository, and uses it to run the provided `water_conservation_exp.jl`
# experiment. That file will run the experiments with both flux and Dirichlet
# boundary conditions, and save the solution results.
# The output data files are saved in the paths water_conserv_exp/ref_soln_flux.csv
# and water_conserv_exp/ref_soln_dirichlet.csv, relative to the directory
# where this script is run.
# Note that this script requires juliaup to be installed.

# Inform the user that the script requires one input argument, if it is not provided
[[ $# -lt 1 ]] && echo "Error! Usage: $0 <output_dir>" && exit 0

# Parse the input argument for the output directory
output_dir=$1
mkdir -p $output_dir

# Clone the ClimaLand.jl repository
git clone https://github.com/CliMA/ClimaLand.jl.git
cd ClimaLand.jl

# Checkout the commit that we know has what we need
git -c advice.detachedHEAD=false checkout d7cc27a9b33227cfc1aa3745a94f3ffcc595fa5c

# Run the experiment using an older version of Julia (requires juliaup)
juliaup add 1.9.0
julia +1.9.0 --project=experiments -e 'using Pkg; Pkg.add(;name="ClimaTimeSteppers", version="0.7.7")'

echo "Running the water conservation experiment..."
julia +1.9.0 --project=experiments ../water_conservation_exp.jl $output_dir
