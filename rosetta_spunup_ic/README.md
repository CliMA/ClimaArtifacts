# Spun up initial conditions for ClimaLand

This artifact includes the data needed by the ClimaLand model to initialize
the land prognostic variables.

We obtain this data by first running the ClimaLand model, forced by
ERA5 data from 1979-1999 for one hundred years (repeating the 20 year period 5 times). The output saved
from this via monthly diagnostics is used as input for the
`create_artifacts.jl` script.

We used the ROSETTA soil parameters for this (see: soil_params_rosetta artifact).

Assume that this monthly diagnostic data is in the directory `filedir`.

Create the artifact by running:
julia --project create_artifacts.jl filedir
