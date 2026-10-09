# Leaf Area Index, derived from MODIS data for 2000-2020

This artifact repackages data coming from:
Hua Yuan, Yongjiu Dai, Zhiqiang Xiao, Duoying Ji, Wei Shangguan,Reprocessing the MODIS Leaf Area Index products for land surface and climate modelling, Remote Sensing of Environment, Volume 115, Issue 5, 2011, Pages 1171-1187, ISSN 0034-4257, https://doi.org/10.1016/j.rse.2011.01.001.

The data is fetched in NetCDF format and reprojected to WGS84 via the GriddingMachine.jl package:
Y. Wang, P. Köhler, R. K. Braghiere, M. Longo, R. Doughty, A. A. Bloom, and C. Frankenberg. 2022. GriddingMachine, a database and software for Earth system modeling at global and regional scales. Scientific Data. 9: 258. [DOI](https://doi.org/10.1038/s41597-022-01346-x)

We regrid the data to 1 degree resolution, correct it for the land fraction of
each cell (see below), and output a netCDF file with the following variables:
  - `lai`  : Leaf area index of the land part of the grid cell, m^2/m^2
  - `land_fraction`: ERA5 land fraction used for the correction
  - `lat`  : Latitude, degrees north
  - `lon`  : Longitude, degrees east
  - `month`: Month of the year, in `DateTime` format

for each year from 2000-2020

To recreate the artifact, run `julia --project create_artifacts.jl` in this
folder (GriddingMachine 0.2 is required).

## Land-fraction correction

The GriddingMachine data averages water pixels (ocean and inland water) as
LAI = 0, so the LAI of a coastal or lake-side 1° cell is approximately
`land_fraction × LAI of its land part`: dividing the LAI of such cells by that
of their fully-land neighbors gives a ratio that tracks the ERA5 land fraction
(slope 1.02) rather than 1. Lake cells are diluted too, which is why the
correction uses the ERA5 land fraction ([`era5_land_fraction`](../era5_land_fraction),
lakes are water) rather than the ETOPO `landsea_mask` (lakes are filled). A
model reading the uncorrected data at a coastal site or grid point sees an LAI
that is too low by the land fraction, for example an annual mean of 1.2 instead
of 5.0 m² m⁻² at the GF-Guy FLUXNET site.

With `f` the 0.1° ERA5 land fraction averaged over each 1° cell
(`land_fraction_correction.jl`):
  - `f ≥ 0.5`: `LAI / f`;
  - `0 < f < 0.5`: mean of the corrected neighbors with `f ≥ 0.5`, or
    `LAI / 0.5` if there is none (isolated islands). Below `f = 0.5`, `LAI / f`
    is biased high because the MODIS and ERA5 coastlines differ within the cell;
  - `f = 0`: extended from the nearest land cells, one ring of cells at a time,
    so that interpolating near a coastline never samples water;
  - values are capped at the largest uncorrected LAI of the year, which only
    binds on a few island cells.

Ratio of the 2000-2020 mean LAI of a cell to that of its fully-land neighbors
(vegetated cells, quartiles):

| ERA5 land fraction | cells | before          | after           |
| ------------------ | ----- | --------------- | --------------- |
| (0, 0.1]           | 135   | 0.01 0.06 0.13  | 0.95 1.02 1.12  |
| (0.1, 0.3]         | 202   | 0.24 0.32 0.45  | 0.95 1.01 1.12  |
| (0.3, 0.5]         | 205   | 0.43 0.51 0.64  | 0.95 1.01 1.10  |
| (0.5, 0.7]         | 238   | 0.48 0.61 0.78  | 0.84 1.00 1.23  |
| (0.7, 0.9]         | 399   | 0.70 0.82 0.97  | 0.86 1.00 1.17  |
| (0.9, 0.99]        | 2194  | 0.85 0.96 1.06  | 0.87 0.98 1.08  |
| (0.99, 1]          | 5275  | 0.91 1.00 1.07  | 0.91 1.00 1.07  |

Cells with `f ≥ 0.99` change by at most 0.056 m² m⁻² (2000-2020 mean).

Because water cells are filled, the files have nonzero LAI over the ocean; use
`land_fraction` to mask it when needed. The uncorrected data is the artifact
with `git-tree-sha1 = "81d4bc1b22e94d66eec3d80a2d21b5dd5303bf8f"`.

License: Creative Commons Zero
