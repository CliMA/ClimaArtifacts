# Earth orography (ETOPO2022 Dataset)


## Overview 

This artifact provides the 30 and 60 arc-second ice-surface orography information 
in NetCDF format. 
- ETOPO_2022_v1_30s_N90W180_surface.nc (30 arc-second, ice surface, 1.5GB)
- ETOPO_2022_v1_60s_N90W180_surface.nc (60 arc-second, ice surface, 456MB)
These artifacts are intended for use with the `ClimaUtilities.SpaceVaryingInputs`
tools to regrid earth's orography onto `ClimaCore` cubed-sphere grids. 


A user guide and additional information for the ETOPO2022 dataset is available here: 
- https://www.ncei.noaa.gov/products/etopo-global-relief-model
- https://www.ngdc.noaa.gov/mgg/global/relief/ETOPO2022/docs/1.2%20ETOPO%202022%20User%20Guide.pdf

## Usage

To recreate the artifact, start a Julia session and activate the 
`earth_orography` project. Then, run the `create_artifact.jl` file. 
e.g. 
```
(earth_orography) pkg>
julia> include("create_artifact.jl")
```

## References

NOAA National Centers for Environmental Information. 2022: ETOPO 2022 15 Arc-Second
Global Relief Model. NOAA National Centers for Environmental Information.
https://doi.org/10.25921/fd45-gt74 . Accessed 10/7/2024.


