# IMERG Land-Sea Mask

This artifact packages the IMERG Land-Sea Mask NetCDF file provided by NASA's
Global Precipitation Measurement (GPM) mission.

## Data

The mask is used in the Integrated Multi-satellitE Retrievals for GPM (IMERG)
algorithm to distinguish land from ocean grid cells.

For more information, see the
[IMERG Land-Sea Mask page](https://gpm.nasa.gov/data/directory/imerg-land-sea-mask-netcdf).

## Prerequisites

1. Julia

## Usage

To recreate this artifact:
1. Clone this repository and navigate to this directory.
2. Run `julia --project=. create_artifact.jl` in the terminal.

## Files

This artifact includes a single file named `IMERG_land_sea_mask.nc`.

## License

NASA data are freely available under the
[NASA Open Data Policy](https://www.earthdata.nasa.gov/engage/open-data-services-software-policies/data-use-guidance).
