# Initial conditions for soil, snow, and canopy

This artifact includes the data needed by the ClimaLand model to partially
initialize the prognostic variables of the land model.

It was generated using a Cartesian domain corresponding to 180x360
grid points in latitude and longitude, and a 15 m vertical extent with
15 layers. The soil was initialized at 98% of saturated, with a temperature
at every level corresponding to the air temperature. The canopy began
with a temperature equal to the air temperature, and moisture
corresponding to a potential equal to the vertical mean of the soil potential.
Snow is initialized with zero liquid water, temperature equal to
the air temperature maxed at 273K, and snow water content set to the value
read from the initial conditions in soil_ic_2008_50m artifact.
Please see commit 9be57aff5200d832c5d90abeb157754ab202921b in
ClimaLand (closed PR#1555) for more details or long run 4402.


Using that commit, run the script
ClimaLand.jl/experiments/long_runs/snowy_land_pmodel.jl with LONGER_RUN
set. The output saved
from this via monthly diagnostics is used as input for the
`create_artifacts.jl` script. 

Assume that this monthly diagnostic data is in the directory `filedir`.

Create the artifact by running:
julia --project create_artifacts.jl filedir

Alternatively, you can call the run_simulation_create_artifact.sh script directly.
Please be aware that this will take around 7 hours to run on an A100 GPU.
The output diagnostics take about 3GB of space; the netcdf file created by
create_artifacts.jl is 12M.

All were created using Julia 1.11.8.
