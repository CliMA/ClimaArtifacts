# MODIS maximum LAI, land-fraction corrected

This artifact contains the 1° maximum leaf area index (LAI) of the *land part*
of each grid cell over 2000-2020: for each cell, the maximum over all months of
the yearly files of the [`modis_lai`](../modis_lai) artifact. The yearly files
are corrected for the land fraction of each cell, since the source data averages
water pixels as LAI = 0; see the [`modis_lai` README](../modis_lai/README.md)
for the correction and its validation. Like the yearly files, the maximum LAI is
nonzero over the ocean, extended from the nearest land cells.

Ratio of the maximum LAI of a cell to that of its fully-land neighbors
(vegetated cells, quartiles):

| ERA5 land fraction | cells | before          | after           |
| ------------------ | ----- | --------------- | --------------- |
| (0, 0.1]           | 163   | 0.01 0.06 0.12  | 0.93 0.99 1.08  |
| (0.1, 0.3]         | 264   | 0.21 0.30 0.44  | 0.92 0.99 1.06  |
| (0.3, 0.5]         | 256   | 0.39 0.49 0.63  | 0.93 0.98 1.06  |
| (0.5, 0.7]         | 307   | 0.49 0.59 0.73  | 0.82 0.98 1.17  |
| (0.7, 0.9]         | 541   | 0.68 0.80 0.96  | 0.83 0.98 1.15  |
| (0.9, 0.99]        | 2762  | 0.85 0.96 1.05  | 0.88 0.98 1.08  |
| (0.99, 1]          | 6843  | 0.91 1.00 1.07  | 0.91 1.00 1.07  |

## Source data

Hua Yuan, Yongjiu Dai, Zhiqiang Xiao, Duoying Ji, Wei Shangguan, Reprocessing
the MODIS Leaf Area Index products for land surface and climate modelling,
Remote Sensing of Environment, Volume 115, Issue 5, 2011, Pages 1171-1187,
ISSN 0034-4257, https://doi.org/10.1016/j.rse.2011.01.001.

## Output format

A single NetCDF file `modis_max_lai.nc` on the 1° grid of `modis_lai`:
  - `lai` (lon, lat): maximum leaf area index of the land part of the cell, m² m⁻²
  - `land_fraction` (lon, lat): ERA5 land fraction used for the correction
  - `lon`, `lat`: cell centers, degrees east and north

To recreate the artifact, run `julia --project create_artifact.jl` in this folder.

## Usage

```julia
using ClimaUtilities.ClimaArtifacts
lai_file = joinpath(@clima_artifact("modis_max_lai"), "modis_max_lai.nc")
```

## License

Creative Commons Zero (same as source data)
