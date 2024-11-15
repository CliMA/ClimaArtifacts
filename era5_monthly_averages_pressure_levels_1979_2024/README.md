# ERA5 monthly averages on pressure levels

This folder creates an artifact by proccessing data coming from
[ERA5 monthly averaged reanalysis](https://cds.climate.copernicus.eu/datasets/reanalysis-era5-pressure-levels-monthly-means?tab=overview)

## Usage

To create the artifact:

1. Set up the CDI APS personal access token following the [instruction](https://cds.climate.copernicus.eu/how-to-api#install-the-cds-api-token),
or enter it in when prompted by the script.
2. Create and activate a python virtual environment
3. In the same terminal run `pip install -r requirements.txt`
4. In the same terminal run `julia --project create_artifact.jl`

## Requirements

- Python >= 3
- 37G of free disk space

## Downloaded data

The unproccessed downloaded dataset contains the following variables:

1. `number` - Not included in output. It is introduced by default by the netCDF conversion
and has a single value of 0.
2. `date`
3. `pressure_level`
4. `latitude`
5. `longitude`
6. `expver`
7. `z`
8. `r`
9. `q`
10. `t`
11. `u`
12. `v`
13. `w`

## Output Dataset

### Spatial Coverage

- 1 degree latitude x 1 degree longitude 2d grid
- -90N to 90N and 0E to 359E
- There are 37 pressure levels from 100Pa to 100000Pa. The spacing between each interval increases
unil 10000Pa. After that point, there is a 2500Pa interval between each point until 25000Pa. From there,
each interval is 5000Pa until 75000Pa, where the interval returns to 2500Pa.
- The latitudes and pressure levels are reversed during processing to be in increasing order

## Temporal Coverage

These files contain Monthly averaged reanalysis from 1979 to present (October 2024 at time of creation), which is produced by averaging all daily data for each month. This results in 12*(2024-1979 + 10/12) = 550 points on the
time dimension, where each point is the 15th of the month that the point represents. For example, the 6th index of `time` is `1979-06-15T00:00:00`,
which represents the whole month of June in 1979.

## Variables

### `expver`

This variable is only defined on the time dimension, and a value of 5 indicates any data at that point on the time axis is from ERA5T, which is an initial release of ERA5 data. A value of 1 indicates that data for that time is no longer potentially subject to change. No preprocessing is done other than removing residual GRIB attributes.

### `z`

This variable is geopotential in units of m^2/s^2, and it is defined on the latitude, longituide, pressure level, and time dimensions.
No processing is done to this variable other than flipping the latitude and pressure level dimensions and removing residual GRIB attributes.

### `r`

This variable is relative humidity as a percentage, and it is defined on the latitude, longituide, pressure level, and time dimensions.
No processing is done to this variable other than flipping the latitude and pressure level dimensions and removing residual GRIB attributes.

### `q`

This variable is specific humidity as a ratio of kg/kg, and it is defined on the latitude, longituide, pressure level, and time dimensions.
No processing is done to this variable other than flipping the latitude and pressure level dimensions and removing residual GRIB attributes.

### `t`

This variable is temperature in units of K, and it is defined on the latitude, longituide, pressure level, and time dimensions.
No processing is done to this variable other than flipping the latitude and pressure level dimensions and removing residual GRIB attributes.

### `u`

This variable is the U component of wind in units of m/s, and it is defined on the latitude, longituide, pressure level, and time dimensions.
No processing is done to this variable other than flipping the latitude and pressure level dimensions and removing residual GRIB attributes.

### `v`

This variable is the V component of wind in units of m/s, and it is defined on the latitude, longituide, pressure level, and time dimensions.
No processing is done to this variable other than flipping the latitude and pressure level dimensions and removing residual GRIB attributes.

### `w`

This variable is vertical velocity in units of Pa/s, and it is defined on the latitude, longituide, pressure level, and time dimensions.
No processing is done to this variable other than flipping the latitude and pressure level dimensions and removing residual GRIB attributes.

## Citation

Hersbach, H., Bell, B., Berrisford, P., Biavati, G., Horányi, A., Muñoz Sabater, J., Nicolas, J., Peubey, C., Radu, R., Rozum, I., Schepers, D., Simmons, A., Soci, C., Dee, D., Thépaut, J-N. (2023): ERA5 monthly averaged data on pressure levels from 1940 to present. Copernicus Climate Change Service (C3S) Climate Data Store (CDS), DOI: 10.24381/cds.6860a573 (Accessed on DD-MMM-YYYY)

## License

See the [LICENSE](LICENSE.txt) file
