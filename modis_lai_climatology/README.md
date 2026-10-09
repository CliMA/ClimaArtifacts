# MODIS LAI monthly climatology, land-fraction corrected

This artifact contains a 1° monthly climatology (2000-2020) of the leaf area
index (LAI) of the *land part* of each grid cell: for each month, the mean of the
21 yearly files of the [`modis_lai`](../modis_lai) artifact. The yearly files
are corrected for the land fraction of each cell, since the source data averages
water pixels as LAI = 0; see the [`modis_lai` README](../modis_lai/README.md)
for the correction and its validation. Like the yearly files, the climatology
has nonzero LAI over the ocean, extended from the nearest land cells.

## Source data

Hua Yuan, Yongjiu Dai, Zhiqiang Xiao, Duoying Ji, Wei Shangguan, Reprocessing
the MODIS Leaf Area Index products for land surface and climate modelling,
Remote Sensing of Environment, Volume 115, Issue 5, 2011, Pages 1171-1187,
https://doi.org/10.1016/j.rse.2011.01.001.

## Output format

A single NetCDF file `modis_lai_climatology.nc` on the 1° grid of `modis_lai`:
  - `lai` (lon, lat, time): leaf area index of the land part of the cell, m² m⁻²
  - `land_fraction` (lon, lat): ERA5 land fraction used for the correction
  - `lon`, `lat`: cell centers, degrees east and north
  - `time`: 12 values, 30 days apart starting 2000-01-01, as required by
    ClimaLand's `PeriodicCalendar`

To recreate the artifact, run `julia --project create_artifact.jl` in this folder.

## Usage

```julia
using ClimaUtilities.ClimaArtifacts
lai_file = joinpath(@clima_artifact("modis_lai_climatology"), "modis_lai_climatology.nc")
```

## License

Creative Commons Zero (same as the `modis_lai` source data).
