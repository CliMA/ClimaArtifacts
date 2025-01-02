# Albedo Data from CESM2

## Overview

This artifact contains scripts that process two Community Earth System Model 2 data files
and creates two output files that contain Albedo data. Below is a detailed description of
each file and its purpose.

## Usage

To recreate the artifact:

Run `julia --project create_artifact.jl`

## Input Files

### 1. `rsds_Amon_CESM2_historical_r1i1p1f1_gn_185001-201412.nc`

This netCDF file contains Surface Downwelling Shortwave Radiation in the variable `rsds`.
This variable is defined on the longitude, latitude, and time dimensions. `rsds` is taken as
the montly average, with the first data point at 15/01/1850 12:00 and the last at 15/12/2014 12:00.
This data file can be downloaded from [LLNL](https://aims3.llnl.gov/thredds/fileServer/css03_data/CMIP6/CMIP/NCAR/CESM2/historical/r1i1p1f1/Amon/rsds/gn/v20190308/rsds_Amon_CESM2_historical_r1i1p1f1_gn_185001-201412.nc
)

### 2. `rsus_Amon_CESM2_historical_r1i1p1f1_gn_185001-201412.nc`

This netCDF file contains Surface Upwelling Shortwave Radiation in the variable `rsus`.
This variable is defined on the longitude, latitude, and time dimensions. `rsus` is taken as
the monthly average, with the first data point at 15/01/1850 12:00 and the last at 15/12/2014 12:00.
This data file can be downloaded from [LLNL](https://aims3.llnl.gov/thredds/fileServer/css03_data/CMIP6/CMIP/NCAR/CESM2/historical/r1i1p1f1/Amon/rsus/gn/v20190308/rsus_Amon_CESM2_historical_r1i1p1f1_gn_185001-201412.nc
)

### 3. `CERES_EBAF_Ed4.2_Subset_200003-201910.nc`

This contains monthly mean top-of-the-atmosphere and surface radiative fluxes from the
Clouds and Earth's Radiant Energy Systems (CERES) Energy Balanced and Filled (EBAF) from March 2000 to October 2019.
The data includes incoming solar flux, upward shortwave and longwave radiative fluxes, and net radiative fluxes
for all-sky and clear-sky conditions. The net radiative fluxes is positive downward. The resolution is 1 deg x 1 deg.
All fluxes are in W m-2. The data was downloaded from [CERES website](https://ceres.larc.nasa.gov/data/)
in September 2024.

## Output Files

### 1. `sw_albedo_Amon_CESM2_historical_r1i1p1f1_gn_185001-201412_v2_no-nans.nc`

This netCDF file contains shortwave albedo in the variable `sw_alb`. The variable is defined
on the longitude, latitude, and time dimensions. `sw_alb` is taken as the monthly average,
with the first data point at 15/01/1850 12:00 and the last at 15/12/2014 12:00. `sw_alb` is
calculated by dividing Surface Upwelling Shortwave Radiation by Surface Downwelling Shortwave Radiation.
At any point, if Surface Downwelling Shortwave Radiation is zero, `sw_alb` is set to 1.0.
`sw_alb` is stored as a Float32.

### 2. `bareground_albedo.nc`

This netCDF file contains average shortwave albedo in the summer for each hemisphere.
The variable is defined on the longitude and latitude. In the northern hemisphere the average
is taken of shortwave albedo during May, June, and July. In the southern hemisphere the average
is taken of shortwave albedo during November, December, and January.
At any point, if data is missing, `sw_alb` is set to 1.0.
`sw_alb` is stored as a Float32.

### 3. `sw_albedo_Amon_CERES_EBAF_Ed4.2_Subset_200003-201910.nc`

This netCDF file contains shortwave albedo in the `sw_alb` variable and shortwave albedo for
clear skies in the `sw_alb_clr` variable. Both variables are defined as monthly averages from
15/03/2000 to 15/10/2019. The shortwave albedo variables are calculated by
dividing Surface Upwelling Shortwave Radiation by Surface Downwelling Shortwave Radiation in
all sky conditions and in clear sky conditions. At any point, if Surface Downwelling Shortwave
Radiation is zero, the calculated albedo is set to 1.0. If at any point the calculated albedo
is greater than 1.0, it is set to 1.0. Both variables are stores as Float32s.

## Scripts

### `calculate_sw_alb.jl`

This script processes `rsds_Amon_CESM2_historical_r1i1p1f1_gn_185001-201412.nc` and
`rsus_Amon_CESM2_historical_r1i1p1f1_gn_185001-201412.nc` to create
`sw_albedo_Amon_CESM2_historical_r1i1p1f1_gn_185001-201412_v2_no-nans.nc`. This is done by
dividing `rsus` by `rsds`, and assigning a value of 1.0 when `rsds` is zero.

### `calculate_bareground_alb.jl`

This script processes `sw_albedo_Amon_CESM2_historical_r1i1p1f1_gn_185001-201412_v2_no-nans.nc`
to create `bareground_albedo.nc` This is done by averaging the input `sw_alb` during the
summer months for each hemisphere. To do this, first mean albedo is calculated globally
for the northern hemisphere summer months. Then, mean albedo is calculated globally
for the southern hemisphere summer months. Then, these two mean albedos are merged, with the
northern hemisphere set to the average during the northern hemisphere summer months and the
southern hemisphere set to the average during the southern hemisphere summer months

### `process_ceres_data.jl`

This script processes `CERES_EBAF_Ed4.2_Subset_200003-201910.nc` to create
`sw_albedo_Amon_CERES_EBAF_Ed4.2_Subset_200003-201910.nc`. The output `sw_alb` variable is
calculated by dividing the input `sfc_sw_up_all_mon` by `sfc_sw_down_all_mon`. The output
`sw_alb_clr` is calculated by dividing `sfc_sw_up_clr_t_mon` by `sfc_sw_down_clr_t_mon`. Both
`sw_alb` and `sw_alb_clr` are set to 1.0 when the calculated value is greater than 1.0, and they
are also set to 1.0 when the flux down is zero.

## References

Danabasoglu, Gokhan (2019). NCAR CESM2 model output prepared for CMIP6 CMIP historical.
Version 20191105.Earth System Grid Federation. [https://doi.org/10.22033/ESGF/CMIP6.7627](https://doi.org/10.22033/ESGF/CMIP6.7627)

Loeb, N. G., D. R. Doelling, H. Wang, W. Su, C. Nguyen, J. G. Corbett, L. Liang, C. Mitrescu, F. G. Rose, and S. Kato, 2018: Clouds and the Earth’s Radiant Energy System (CERES) Energy Balanced and Filled (EBAF) Top-of-Atmosphere (TOA) Edition-4.0 Data Product. J. Climate, 31, 895-918, doi: [10.1175/JCLI-D-17-0208.1](https://journals.ametsoc.org/doi/pdf/10.1175/JCLI-D-17-0208.1)

Kato, S., F. G. Rose, D. A. Rutan, T. E. Thorsen, N. G. Loeb, D. R. Doelling, X. Huang, W. L. Smith, W. Su, and S.-H. Ham, 2018: Surface irradiances of Edition 4.0 Clouds and the Earth’s Radiant Energy System (CERES) Energy Balanced and Filled (EBAF) data product, J. Climate, 31, 4501-4527, doi: [10.1175/JCLI-D-17-0523.1](https://journals.ametsoc.org/doi/pdf/10.1175/JCLI-D-17-0523.1)

## License

This dataset is distributed under the Creative Commons Attribution 4.0 International License, permitting use, distribution, and reproduction in any medium, provided the original work is properly cited.
