# ERA5 monthly averages 1979-2024

This folder creates four artifacts by processing data coming from [ERA5 monthly averaged reanalysis](https://cds.climate.copernicus.eu/datasets/reanalysis-era5-single-levels-monthly-means?tab=download) and contains
monthly averaged surface fluxes and runoff rates.

The first artifact contains the monthly averaged reanalysis of surface variables, the second contains monthly averaged reanalysis of vertically integrated variables
the third contains monthly averaged reanalysis of surface variables by hour of day, and the fourth contains
monthly averaged reanalysis of vertically integrated variables by hour of day

## Usage

To recreate all four artifacts:

1. Set up the CDI APS personal access token following the [instruction](https://cds.climate.copernicus.eu/how-to-api#install-the-cds-api-token),
or enter it in when prompted by the script.
2. Create and activate a python virtual environment
3. In the same terminal run `pip install -r requirements.txt`
4. In the same terminal run `julia --project create_artifact.jl`

Note: The script first downloads the monthly averaged reanalysis data, and then does the same for the monthly averaged reanalysis by hour of day data. Downloading and processing the hourly averages per month takes significantly longer because it contains 24 times more data.

## Requirements

- Python >= 3
- 22G of free disk space

## Downloaded datasets

Both of the downloaded datasets contain the following variables:

1. `mean_surface_downward_long_wave_radiation_flux`
2. `mean_surface_downward_short_wave_radiation_flux`
3. `mean_surface_latent_heat_flux`
4. `mean_surface_net_long_wave_radiation_flux`
5. `mean_surface_net_short_wave_radiation_flux`
6. `mean_surface_sensible_heat_flux`
7. `mean_surface_runoff_rate`
8. `mean_sub_surface_runoff_rate`
9. `total_column_water`
10. `number` - Not included in output. It is introduced by default by the netCDF conversion and has a single value of 0.
11. `expver`

## Output Datasets

Running the script results in two output datasets:

1. `era5_monthly_surface_fluxes_197901-202410.nc` (around 420M)
2. `era5_monthly_surface_fluxes_hourly_197901-202410.nc` (around 8.4G)

Both of the average for each hour for each month and averages per months datasets contain the same variables and spatial coverage, but the variables are defined on different time dimensions.

### Spatial Coverage (Identical in all four)

- 1 degree latitude x 1 degree longitude grid
- -90N to 90N and 0E to 359E
- The latitudes are reversed during processing to be in increasing order

## Temporal Coverage

The output files have different temporal coverage:

### monthly averages

The datasets with this temporal coverage are:
- `era5_monthly_averages_atmos_single_level_197901-202410.nc`
- `era5_monthly_averages_surface_single_level_197901-202410.nc`

These files contain Monthly averaged reanalysis from 1979 to present (October 2024 at time of creation), which is produced by averaging all daily data for each month. This results in 12*(2024-1979 + 10/12) = 550 points on the
time dimension, where each point is the 15th of the month that the point represents. For example, the 6th index of `time` is `1979-06-15T00:00:00`,
which represents the whole month of June in 1979.

### average for each hour for each month

The datasets with this temporal coverage are:
- `era5_monthly_averages_atmos_single_level_hourly_197901-202410.nc`
- `era5_monthly_averages_surface_single_level_hourly_197901-202410.nc`

These files contain Monthly averages by hour of day from 1979 to present (October 2024 at time of creation), which constitutes the average over all data within the calendar month for every hour.
This results in 12 * 24 * (2024-1979 )=13200 points on the time dimension, where each point represents the average of a given hour across the month. For example, the 12th index of `time` is `1979-01-15T11:00:00`, which represents the average of each 11:00-12:00 across the month of January in 1979.


## Surface Variables

These following variables are in:
- `era5_monthly_averages_surface_single_level_197901-202410.nc`
- `era5_monthly_averages_surface_single_level_hourly_197901-202410.nc`

The following variables are stored as Float32s and are defined on the latitude, longitude, and time dimensions:

### `mslhf`

This is the mean surface latent heat flux in units of W m**-2. No processing is done to this variable other than flipping the latitude dimension and removing residual GRIB attributes.

### `msshf`

This is the mean surface sensible heat flux in units of W m**-2. No processing is done to this variable other than flipping the latitude dimension and removing residual GRIB attributes.

### `mssror`

This is the mean sub-surface runoff rate in units of kg m**-2 s**-1. No processing is done to this variable other than flipping the latitude dimension and removing residual GRIB attributes.

### `msror`

This is the mean surface runoff rate in units of kg m**-2 s**-1. No processing is done to this variable other than flipping the latitude dimension and removing residual GRIB attributes.

### `msuwlwrf`

This is the mean surface upward long-wave radiation flux in units of W m**-2.
This variable is created during processing by taking the difference of
mean surface downward long-wave radiation flux and mean surface net long-wave radiation flux, and then flipping the latitude dimension.
Residual GRIB attributes are also removed.

### `msuwswrf`

This is the mean surface upward short-wave radiation flux in units of W m**-2.
This variable is created during processing by taking the difference of
mean surface downward short-wave radiation flux and mean surface net short-wave radiation flux, and then flipping the latitude dimension. Residual GRIB attributes are also removed.

### `expver`

This variable is only defined on the time dimension, and a value of 5 indicates any data at that point on the time axis is from ERA5T, which is an initial release of ERA5 data. A value of 1 indicates that data for that time is no longer potentially subject to change. No preprocessing is done other than removing residual GRIB attributes. It is not included in the hourly dataset.

## Vertically Integrated Variables

These following variables are in:
- `era5_monthly_averages_atmos_single_level_197901-202410.nc`
- `era5_monthly_averages_atmos_single_level_hourly_197901-202410.nc`

The following variables are stored as Float32s and are defined on the latitude, longitude, and time dimensions:

### `tcw`

This is the total water column in units of  kg m**-2. No processing is done to this variable other than flipping the latitude dimension and removing residual GRIB attributes.

### `expver`

This variable is only defined on the time dimension, and a value of 5 indicates any data at that point on the time axis is from ERA5T, which is an initial release of ERA5 data. A value of 1 indicates that data for that time is no longer potentially subject to change. No preprocessing is done other than removing residual GRIB attributes. It is not included in the hourly dataset.

## Citation

Hersbach, H., Bell, B., Berrisford, P., Biavati, G., Horányi, A., Muñoz Sabater, J., Nicolas, J., Peubey, C., Radu, R., Rozum, I., Schepers, D., Simmons, A., Soci, C., Dee, D., Thépaut, J-N. (2023): ERA5 monthly averaged data on pressure levels from 1940 to present. Copernicus Climate Change Service (C3S) Climate Data Store (CDS), DOI: 10.24381/cds.6860a573 (Accessed on 11-11-2024)

## License

See the [LICENSE](LICENSE.txt) file
