# Subset of datasets found on ILAMB — ecosystem respiration and net ecosystem exchange

## Overview
This artifact contains a subset of datasets on ILAMB which includes `.nc` files for
ecosystem respiration (`reco`) and net ecosystem exchange (`nee`), both from FLUXCOM.
This artifact is used for comparing simulation data from ClimaLand with observational
data.

## Usage
To recreate the artifact:
1. Navigate to this directory in the terminal.
1. Run `julia --project=. create_artifact.jl`

## Files

All files in this artifact are from the ILAMB dataset which can be found here:
[https://www.ilamb.org/ILAMB-Data/](https://www.ilamb.org/ILAMB-Data/)

### 1. `reco_FLUXCOM_reco.nc`
This `.nc` file is the FLUXCOM dataset containing observational data for ecosystem
respiration. The latitude dimension (and subsequently, the data along this axis) is
reversed.

### 2. `nee_FLUXCOM_nee.nc`
This `.nc` file is the FLUXCOM dataset containing observational data for net ecosystem
exchange. The latitude dimension (and subsequently, the data along this axis) is
reversed.

## References
For more information about the `reco_FLUXCOM_reco.nc` and `nee_FLUXCOM_nee.nc` files, refer to the following publications:
Jung, M., M. Reichstein, C.R. Schwalm, C. Huntingford, S. Sitch, A. Ahlstrom, A. Arneth, G. Camps-Valls, P. Ciais, P. Friedlingstein, F. Gans, K. Ichii, A.K. Jain, E. Kato, D. Papale, B. Poulter, B. Raduly, C. Rodenbeck, G. Tramontana, N. Viovy, Y.P. Wang, U. Weber, S. Zaehle and N. Zeng (2017), Compensatory water effects link yearly global land CO2 sink changes to temperature, Nature, 541, 516-520, doi:10.1038/nature20780

Tramontana, G., M. Jung, C.R. Schwalm, K. Ichii, G. Camps-Valls, B. Raduly, M. Reichstein, M.A. Arain, A. Cescatti, G. Kiely, L. Merbold, P. Serrano-Ortiz, S. Sickert, S. Wolf, and D. Papale (2016), Predicting carbon dioxide and energy fluxes across global FLUXNET sites with regression algorithms, Biogeosciences, 13, 4291-4313, doi:10.5194/bg-13-4291-2016

# Licenses
### 1. `reco_FLUXCOM_reco.nc`
License: Creative Commons 4.0 BY

### 2. `nee_FLUXCOM_nee.nc`
License: Creative Commons 4.0 BY
