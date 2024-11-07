# ERA5 monthly averages

This artifact processes data coming from [ERA5 monthly averaged reanalysis](https://cds.climate.copernicus.eu/datasets/reanalysis-era5-single-levels-monthly-means?tab=download) and contains
monthly averaged surface fluxes and runoff rates.

The input file contains both Monthly averaged reanalysis and Monthly averaged reanalysis by hour of day. During processing, these are split into two different files.

## Usage

To recreate the artifact:

1. Set up the CDI APS personal access token following the [instruction](https://cds.climate.copernicus.eu/how-to-api#install-the-cds-api-token),
or enter it in when prompted by the script.
2. Create and activate a python virtual environment
3. In the same terminal run `pip install -r requirements.txt`
4. In the same terminal run `julia --project create_artifact.jl`

## Requirements

- Python >= 3

## Downloaded dataset

The downloaded dataset contains the following variables:

1. `mean_surface_downward_long_wave_radiation_flux`
2. `mean_surface_downward_short_wave_radiation_flux`
3. `mean_surface_latent_heat_flux`
4. `mean_surface_net_long_wave_radiation_flux`
5. `mean_surface_net_short_wave_radiation_flux`
6. `mean_surface_sensible_heat_flux`
7. `mean_surface_runoff_rate`
8. `mean_sub_surface_runoff_rate`

## Output datasets

There processing of the downloaded dataset results in two output datasets:

1. `era5_monthly_surface_fluxes_200801-200812.nc`
2. `era5_monthly_surface_fluxes_hourly_200801-200812.nc`

Both of the output datasets contain the same variables and spatial coverage, but the variables are defined on different time dimensions.

## Spatial Coverage

- 1 degree latitude x 1 degree longitude grid
- -90N to 90N and 0E to 359E
- The latitudes are reversed during processing to be in increasing order

The shared variables, which are all stored as Float32s and defined on the latitude, longitude, and time dimensions, are:

## `mslhf`

This is the mean surface latent heat flux in units of W m**-2. No processing is done to this variable other than flipping the latitude dimension.

## `msshf`

This is the mean surface sensible heat flux in units of W m**-2. No processing is done to this variable other than flipping the latitude dimension.

## `mssror`

This is the mean sub-surface runoff rate in units of kg m**-2 s**-1. No processing is done to this variable other than flipping the latitude dimension.

## `msror`

This is the mean surface runoff rate in units of kg m**-2 s**-1. No processing is done to this variable other than flipping the latitude dimension.

## `msuwlwrf`

This is the mean surface upward long-wave radiation flux in units of W m**-2.
This variable is created during processing by taking the difference of
mean surface downward long-wave radiation flux and mean surface net long-wave radiation flux, and then flipping the latitude dimension.

## `msuwswrf`

This is the mean surface upward short-wave radiation flux in units of W m**-2.
This variable is created during processing by taking the difference of
mean surface downward short-wave radiation flux and mean surface net short-wave radiation flux, and then flipping the latitude dimension.

## Temporal Coverage

The two output files have different temporal coverage.

### `era5_monthly_surface_fluxes_200801-200812.nc`

This file contains Monthly averaged reanalysis, which is produced by averaging all daily data for each month. This results in 12 points on the
time dimension, where each point in the 15th of the month that the point represents. For example, the 6th index of `time` is 2008-06-15T00:00:00,
which represents the whole month of June in 2008.

### `era5_monthly_surface_fluxes_hourly_200801-200812.nc`

This file contains Monthly averages by hour of day, which constitutes the average over all data within the calendar month for every hour. This results in 12*24=288 points on the time dimension, where each point represents the average of a given hour across the month. For example, the 12th index of
`time` is 2008-01-15T11:00:00, which represents the average of each 11:00-12:00 across the month of January in 2008.

## Citation

Hersbach, H., Bell, B., Berrisford, P., Biavati, G., Horányi, A., Muñoz Sabater, J., Nicolas, J., Peubey, C., Radu, R., Rozum, I., Schepers, D., Simmons, A., Soci, C., Dee, D., Thépaut, J-N. (2023): ERA5 monthly averaged data on single levels from 1940 to present. Copernicus Climate Change Service (C3S) Climate Data Store (CDS), DOI: 10.24381/cds.f17050d7 (Accessed on DD-MMM-YYYY)

## License

See the [LICENSE](LICENSE.txt) file