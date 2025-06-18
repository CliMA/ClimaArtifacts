# 3S-GEOPROF-COMB Dataset from combined CloudSat and CALIPSO observations

This artifact repackages data coming from the [3S-GEOPROF-COMB
Dataset](https://zenodo.org/records/12768877) and contains seasonal data from
2006 JJA (June, July, August) to 2020 JJA. In particular, the data is from
`radarlidar_seasonal_2.5x2.5.zip` and `radarlidar_seasonal_10x10.zip`.

## Data

In the NetCDF file, there is the `doop` dimension and `type` dimension. The
`doop` dimension in the CloudSat/CALIPSO 3S-GEOPROF-COMB dataset stands for
"Daylight-Only Operations" and is used to handle a significant operational
change that occurred in the CloudSat mission. The `doop` dimension provides
users with two coordinate options:
- "All cases" - Uses all available observations with no subsampling applied
  (full data from 2006-2011, then DO-Op data from 2012 onward).
- "DO-Op observable" - Uses only profiles that either were collected or would
  have been collected under DO-Op mode constraints (applies DO-Op sampling
  patterns to the entire dataset for consistency).
The `type` dimension defines the different kinds of cloud criteria for the
profiles. These types are:
- "any" - Any cloud is in the profile.
- "thick" - Cloud layer is greater than or equal to 4.8 km thick.
- "high" - Cloud is present in a pressure range of less than 440 hPa.
- "middle" - Cloud is present in a pressure range between 440 and 680 hPa.
- "low" - Cloud is present in a pressure range greater than 680 hPa.
- "uniquehigh" - Same as "high", but all cloud in the profile is in the same
  pressure range.
- "uniquemiddle" - Same as "middle", but all cloud in the profile is in the same
  pressure range.
- "uniquelow" - Same as "low", but all cloud in the profile is in the same
  pressure range.

The relevant variables are:
- Number of observations of cloud at altitude (height × lon × lat × doop × time; `cloud_counts_on_levels`)
- Number of observations at altitude (height × lon × lat × doop × time; `total_counts_on_levels`)
- Number of times cloud of (type) present in column (lon × lat × doop × type × time; `cloud_counts_in_column`)
- Number of observations of whole column (lon × lat × doop × type × time; `total_counts_in_column`)
- Estimated count of attenuated lidar samples at level (height × lon × lat × doop × time; `attenuated_lidar_counts_on_levels`)
- Count of lidar attenuation estimated anywhere in column (lon × lat × doop × time, `attenuated_lidar_counts_in_column`)
- Count of no radar observation due to surface clutter at level (height × lon × lat × doop × time; `radar_surface_clutter_counts_on_levels`)
- Number of overpasses of grid cell (lon × lat × doop × time; `n_overpasses`)
- Number of unique days grid cell observed (lon × lat × doop × time; `n_days`)
- Number of profiles in local time bins (lon × lat × doop × localhour × time; `localhour_counts`)
- Maximum and minimum height of bin range (above mean sea level) (bound × height; `height_bounds`)
- Cloud counts at level divided by total counts at level x 100 (height × lon × lat × doop × time; `cloud_fraction_on_levels`)
- Cloud counts in column of type divided by total counts of type in column x 100 (lon × lat × doop × type × time;        `cloud_cover_in_column`)

For more information about the data, refer to the documentation on
[Zenodo](https://zenodo.org/records/12768877) and
[GitHub](https://github.com/bertrandclim/3S-GEOPROF-COMB).

## Prerequisites

1. Julia
2. Python
3. 3.9GiB to download and extract the data from the downloaded zip files.

## Usage

To recreate this artifact:
1. Clone this repository and navigate to this directory.
2. Run `python download_cloudsat.py` to download and unextract the files in the
   directory relative to `download_cloudsat.py`. The python script does not have
   any external dependencies that does not already come with Python.
3. Run `julia --project=.` and run `include("create_artifact.jl")` in the
   terminal.

## Postprocesing

All time-varying quantities are concatenated along the time dimension. Any
global attribute that differs between the datasets is represented as a vector,
while any global attribute that remains the same is included as a single value.

## Files

The files included are `radarlidar_seasonal_2.5x2.5.nc` and
`radarlidar_seasonal_10x10.nc`, a lower resolution version of
`radarlidar_seasonal_2.5x2.5.nc`. The size of `radarlidar_seasonal_2.5x2.5.nc`
is 3.1GiB and the size of `radarlidar_seasonal_10x10.nc` is 196MiB.

## License

Creative Commons Attribution 4.0 International.

More information about this license can be found
[here](https://creativecommons.org/licenses/by/4.0/legalcode).

## Citation

Bertrand, L., Kay, J. E., Haynes, J., & de Boer, G. (2024). 3S-GEOPROF-COMB: A
Global Gridded Dataset for Cloud Vertical Structure from combined CloudSat and
CALIPSO observations (0.8.4) [Data set]. Zenodo.
https://doi.org/10.5281/zenodo.12768877
