#!/bin/bash

# This script downloads a specific version of a Matlab script from a GitHub repository
# and generates data files for two different soil types using that script.
# The output data files are saved in the paths bonanmodeling/sp_08_01/bonan_data_clay.txt
# and bonanmodeling/sp_08_01/bonan_data_sand.txt, relative to the directory
# where this script is run.

# Inform the user that the script requires one input argument, if it is not provided
[[ $# -lt 1 ]] && echo "Error! Usage: $0 <output_dir>" && exit 0

# Parse the input argument for the output directory
output_dir=$1

# Clone the repository containing the Matlab script we need
git clone https://github.com/gbonan/bonanmodeling.git
cd bonanmodeling

# Checkout the commit that we know has what we need
git -c advice.detachedHEAD=false checkout a10cf764013be58c2def1dbe7c7e52a3213e061e

# Comment out Bonan's Haverkamp formulation for hydraulic conductivity (K)
# This will use the van Genuchten formulation instead, as is done in ClimaLand.jl
awk '{if (NR>33&&NR<42) $0 = "%" substr($0, 2); print}' sp_08_01/van_Genuchten.m > tmpfile && mv tmpfile sp_08_01/van_Genuchten.m

# Load the Matlab module on Caltech's Central cluster
# NOTE: You will need to change it if running on a different machine
module load matlab/r2024a

# Run the Matlab script to generate the data for the sand soil type
matlab -batch "run('sp_08_01/sp_08_01.m'); exit;"

# Remove the header (first line) and rename the generated data file
tail -n +2 sp_08_01/data1.txt > "../$output_dir/bonan_data_sand.txt"

# Comment out lines 60-66 of sp_08_01.m and uncomment lines 69-75
# This changes the soil type parameters used for the experiment
awk '{if (NR>59&&NR<67) $0 = "%" substr($0, 2); print}' sp_08_01/sp_08_01.m > tmpfile && mv tmpfile sp_08_01/sp_08_01.m
awk '{if (NR>68&&NR<76) $0 = " " substr($0, 2); print}' sp_08_01/sp_08_01.m > tmpfile && mv tmpfile sp_08_01/sp_08_01.m

# Run the Matlab script again to generate the data for the clay soil type
matlab -batch "run('sp_08_01/sp_08_01.m'); exit;"

# Remove the header (first line) and rename the generated data file
tail -n +2 sp_08_01/data1.txt > "../$output_dir/bonan_data_clay.txt"
