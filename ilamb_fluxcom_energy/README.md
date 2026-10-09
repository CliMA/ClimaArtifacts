# Subset of datasets found on ILAMB — FLUXCOM latent and sensible heat fluxes

## Overview
This artifact contains a subset of datasets on ILAMB which includes `.nc` files for
the surface latent heat flux (`hfls`) and the surface sensible heat flux (`hfss`), both
from FLUXCOM. This artifact is used for calibrating ClimaLand and for comparing
simulation data from ClimaLand with observational data.

## Usage
To recreate the artifact:
1. Navigate to this directory in the terminal.
1. Run `julia --project=. create_artifact.jl`

## Files

All files in this artifact are from the ILAMB dataset which can be found here:
[https://www.ilamb.org/ILAMB-Data/](https://www.ilamb.org/ILAMB-Data/)

Both files are monthly means on a 0.5° x 0.5° grid from January 1980 to December 2016,
in units of `MJ m-2 day-1` (divide by 0.0864 to get `W m-2`), positive upward (from
the surface to the atmosphere). The latitude dimension (and subsequently, the data
and latitude bounds along this axis) is reversed so that latitudes are increasing.

### 1. `hfls_FLUXCOM_hfls.nc`
This `.nc` file is the FLUXCOM dataset containing observational data for the surface
latent heat flux.

### 2. `hfss_FLUXCOM_hfss.nc`
This `.nc` file is the FLUXCOM dataset containing observational data for the surface
sensible heat flux.

## References
For more information about the `hfls_FLUXCOM_hfls.nc` and `hfss_FLUXCOM_hfss.nc` files, refer to the following publications:
Jung, M., S. Koirala, U. Weber, K. Ichii, F. Gans, G. Camps-Valls, D. Papale, C. Schwalm, G. Tramontana, and M. Reichstein (2019), The FLUXCOM ensemble of global land-atmosphere energy fluxes, Scientific Data, 6, 74, doi:10.1038/s41597-019-0076-8

Tramontana, G., M. Jung, C.R. Schwalm, K. Ichii, G. Camps-Valls, B. Raduly, M. Reichstein, M.A. Arain, A. Cescatti, G. Kiely, L. Merbold, P. Serrano-Ortiz, S. Sickert, S. Wolf, and D. Papale (2016), Predicting carbon dioxide and energy fluxes across global FLUXNET sites with regression algorithms, Biogeosciences, 13, 4291-4313, doi:10.5194/bg-13-4291-2016

# Licenses
### 1. `hfls_FLUXCOM_hfls.nc`
License: Creative Commons 4.0 BY

### 2. `hfss_FLUXCOM_hfss.nc`
License: Creative Commons 4.0 BY
