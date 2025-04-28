# Initial conditions for soil and snow, Jan 1, 2008

This artifact includes the data needed by the ClimaLand model to initialize
the soil and snow model prognostic variables for Jan 1, 2008, after an
appropriate spin-up period. The soil domain is 50 m deep, with 15
elements, and 
approximately 1x1 degrees resolution in the horizontal.

We obtain this data by first running the ClimaLand model, forced by
ERA5 data from 2008, for two years continuously. The script to do this is:
ClimaLand.jl/experiments/long_runs/snowy_land.jl. The output saved
from this via monthly diagnostics is used as input for the
`create_artifacts.jl` script. 

Assume that this monthly diagnostic data is in the directory `filedir`.

Create the artifact by running:
julia --project create_artifacts.jl filedir
