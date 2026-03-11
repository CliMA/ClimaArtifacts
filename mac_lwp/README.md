# Multisensor Advanced Climatology Mean Liquid Water Path Dataset

This artifact repackages data coming from the
[Multi-Sensor Advanced Climatology of Liquid Water Path (MAC-LWP) data set](https://cmr.earthdata.nasa.gov/search/concepts/C1368521971-GES_DISC.html)
and contains monthly 1-degree ocean-only mean estimates of cloud liquid water
path from 1988 to 2016.

## Data

The two variables in the MAC-LWP data set are:
- `cloudlwp`: Monthly average of cloud liquid water path
- `cloudlwp_error`: 1-sigma error of the monthly average of cloud liquid water
  path

Dimensions:
- `lon`: 360 (0.5 to 359.5 degrees east, 1-degree resolution)
- `lat`: 180 (-89.5 to 89.5 degrees north, 1-degree resolution)
- `time`: 348 (monthly, January 1988 to December 2016)
- `lon_bnds`: 2 x 360 (boundary values for `lon` and `lat`)
- `lat_bnds`: 2 x 180 (boundary values for `lon` and `lat`)

Variables:
- `cloudlwp(time, lat, lon)`: Monthly average cloud liquid water path (g/m^2)
- `cloudlwp_error(time, lat, lon)`: 1-sigma error on monthly average cloud
  liquid water path (g/m^2)
- `lon(lon)`, `lon_bnds(lon, bnds)`: Longitude and bounds
- `lat(lat)`, `lat_bnds(lat, bnds)`: Latitude and bounds
- `time(time)`: Seconds since 1988-01-01 00:00:00

For more information about the data, refer to the
[The Multisensor Advanced Climatology of Liquid Water Path](https://journals.ametsoc.org/view/journals/clim/30/24/jcli-d-16-0902.1.xml)
paper.

## Prerequisites

1. Julia
2. 710MiB to download, preprocess, and create the artifact.

## Usage

To recreate this artifact:
1. Register for an Earthdata account. See
   [this](https://www.earthdata.nasa.gov/data/earthdata-login#toc-how-do-i-register-with-earthdata-login)
   for instructions.
2. Link GES DISC with your Earthdata account. See
   [this](https://disc.gsfc.nasa.gov/earthdata-login) for instructions.
3. Generate the .netrc prerequisite file. See
   [this](https://disc.gsfc.nasa.gov/information/howto?title=How%20to%20Generate%20Earthdata%20Prerequisite%20Files)
   for instructions.
4. Clone this repository and navigate to this directory.
5. Run `julia --project=. create_artifact.jl` in the terminal.

## Postprocessing

The original dataset comprises 29 NetCDF files, one per year from 1988 to 2016,
each containing 12 monthly time steps. These files were concatenated along the
time dimension into a single file.

The `time` variable in the original files uses a per-file month index (0–11,
relative to the start of each year), which is incompatible across files. This
was replaced with a uniform time axis of `DateTime` values starting from
1988-01-01 and incrementing by one month, stored as seconds since
1988-01-01 00:00:00.

Missing values were replaced with `NaN` in the output file.

## Files

This artifact includes a single file named `mac_lwp.nc` (173 MiB).

## License

Creative Commons Zero (CC0)

For more information about the license used from the NASA's Earth Science Data
and Information System (ESDIS) Project, see
[this](https://www.earthdata.nasa.gov/engage/open-data-services-software-policies/data-use-guidance)

## Citation

Teixeira, Joao. “Multisensor Advanced Climatology Mean Liquid Water Path L3
Monthly 1 Degree x 1 Degree V1.” NASA Goddard Earth Sciences Data and
Information Services Center, 2016. doi:10.5067/MEASURES/MACLWPM. Date Accessed:
2026-03-11
