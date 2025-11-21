# Initial conditions for soil, Jan 1, 2008

This artifact includes the data needed by the ClimaLand model to initialize the
soil model prognostic variables for Jan 1, 2008, after an appropriate spin-up
period. The soil domain is 50 m deep, with 15 elements, and approximately
0.2x0.2 degrees resolution in the horizontal.

We obtain this data by first running the ClimaLand model, forced by ERA5 data
from 2008, for two years continuously. The script to do this is:
ClimaLand.jl/experiments/long_runs/snowy_land.jl. The output saved from this via
monthly diagnostics is used as input for the `create_artifacts.jl` script.

This can be be done by the running `bash run_snowy_land.sh <file_directory>
<true/false>, where the boolean refers to using CUDA or not. For instance, one
can change directory to where this `README.md` is located by `cd
soil_ic_2008_50_m` and run `bash run_snowy_land.sh . true` to start a snowy land
long run with CUDA. After the simulation is done running, the terminal will
print a file path for you to copy and use as an input for `create_artifacts.jl`.

Assume that this monthly diagnostic data is in the directory `filedir`.

Create the artifact by running:
julia --project create_artifacts.jl filedir
