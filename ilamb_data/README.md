# Subset of datasets found on ILAMB

## Overview
This artifact contains a subset of datasets on ILAMB which includes `.nc` files for
evapotranspiration (`et`) from MODIS, gross primary productivity (`gpp`) from FLUXCOM,
surface upward LW radiation (`rlus`) from CERESed4.1, and surface upward SW radiation
(`rsus`) from CERESed4.1. This artifact is used for comparing simulation data from ClimaLand
with observational data.

## Usage
To recreate the artifact:
1. Navigate to this directory in the terminal.
1. Run `julia --project=. create_artifact.jl`

## Files

All files in this artifact are from the ILAMB dataset which can be found here:
[https://www.ilamb.org/ILAMB-Data/](https://www.ilamb.org/ILAMB-Data/)

### 1. `evspsbl_MODIS_et_0.5x0.5.nc`
This `.nc` file is the MODIS dataset containing observational data for evapotranspiration.
No preprocessing is done for this file.

### 2. `gpp_FLUXCOM_gpp.nc`
This `.nc` file is the FLUXCOM dataset containing observational data for gross primary
productivity. The latitude dimension (and subsequently, the data along this axis) is
reversed.

### 3. `rlus_CERESed4.2_rlus.nc`
This `.nc` file is the CERESed4.2 dataset containing observational data for surface upward
LW radiation. No preprocessing is done for this file.

### 4. `rsus_CERESed4.2_rsus.nc`
This `.nc` file is the CERESed4.2 dataset containing observational data for surface upward
SW radiation. No preprocessing is done for this file.

## References
For more information about the `evspsbl_MODIS_et_0.5x0.5.nc` file, refer to the following publication:
Running, S., Q. Mu, M. Zhao. MODIS/Terra Net Evapotranspiration 8-Day L4 Global 500m SIN Grid V061. 2021, distributed by NASA EOSDIS Land Processes Distributed Active Archive Center, https://doi.org/10.5067/MODIS/MOD16A2.061. Accessed 2024-10-24.

For more information about the `gpp_FLUXCOM_gpp.nc` file, refer to the following publications:
Jung, M., M. Reichstein, C.R. Schwalm, C. Huntingford, S. Sitch, A. Ahlstrom, A. Arneth, G. Camps-Valls, P. Ciais, P. Friedlingstein, F. Gans, K. Ichii, A.K. Jain, E. Kato, D. Papale, B. Poulter, B. Raduly, C. Rodenbeck, G. Tramontana, N. Viovy, Y.P. Wang, U. Weber, S. Zaehle and N. Zeng (2017), Compensatory water effects link yearly global land CO2 sink changes to temperature, Nature, 541, 516-520, doi:10.1038/nature20780

Tramontana, G., M. Jung, C.R. Schwalm, K. Ichii, G. Camps-Valls, B. Raduly, M. Reichstein, M.A. Arain, A. Cescatti, G. Kiely, L. Merbold, P. Serrano-Ortiz, S. Sickert, S. Wolf, and D. Papale (2016), Predicting carbon dioxide and energy fluxes across global FLUXNET sites with regression algorithms, Biogeosciences, 13, 4291-4313, doi:10.5194/bg-13-4291-2016

For more information about the `rlus_CERESed4.2_rlus.nc` file, refer to the following publications:
Loeb, N.G., D.R. Doelling, H. Wang, W. Su, C. Nguyen, J.G. Corbett, L. Liang, C. Mitrescu, F.G. Rose, and S. Kato (2018), Clouds and the Earth's Radiant Energy System (CERES) Energy Balanced and Filled (EBAF) Top-of-Atmosphere (TOA) Edition-4.0 Data Product, Journal of Climate, 31(2), 895-918, doi:10.1175/JCLI-D-17-0208.1

Kato, S., F. G. Rose, D. A. Rutan, T. E. Thorsen, N. G. Loeb, D. R. Doelling, X. Huang, W. L. Smith, W. Su, and S.-H. Ham (2018), Surface irradiances of Edition 4.0 Clouds and the Earth's Radiant Energy System (CERES) Energy Balanced and Filled (EBAF) data product, Journal of Climate, 31, 4501-4527, doi:10.1175/JCLI-D-17-0523.1

For more information about the `rsus_CERESed4.2_rsus.nc` file, refer to the following publications:
Loeb, N.G., D.R. Doelling, H. Wang, W. Su, C. Nguyen, J.G. Corbett, L. Liang, C. Mitrescu, F.G. Rose, and S. Kato (2018), Clouds and the Earth's Radiant Energy System (CERES) Energy Balanced and Filled (EBAF) Top-of-Atmosphere (TOA) Edition-4.0 Data Product, Journal of Climate, 31(2), 895-918, doi:10.1175/JCLI-D-17-0208.1

Kato, S., F. G. Rose, D. A. Rutan, T. E. Thorsen, N. G. Loeb, D. R. Doelling, X. Huang, W. L. Smith, W. Su, and S.-H. Ham (2018), Surface irradiances of Edition 4.0 Clouds and the Earth's Radiant Energy System (CERES) Energy Balanced and Filled (EBAF) data product, Journal of Climate, 31, 4501-4527, doi:10.1175/JCLI-D-17-0523.1

# Licenses
### 1. `evspsbl_MODIS_et_0.5x0.5.nc`
License: Creative Commons Zero

### 2. `gpp_FLUXCOM_gpp.nc`
License: Creative Commons 4.0 BY

### 3. `rlus_CERESed4.2_rlus.nc`
License: Creative Commons Zero

### 4. `rsus_CERESed4.2_rsus.nc`
License: Creative Commons Zero
