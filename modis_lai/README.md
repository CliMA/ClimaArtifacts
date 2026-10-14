# Leaf Area Index, derived from MODIS data for 2000-2020

This recipe creates the `modis_lai_0.25deg` artifact (136 MB) with the monthly
leaf area index (LAI) of the *land part* of each 0.25° grid cell, for each year
from 2000 to 2020, in files `Yuan_et_al_YYYY_0.25x0.25.nc`.

The data comes from:
Hua Yuan, Yongjiu Dai, Zhiqiang Xiao, Duoying Ji, Wei Shangguan,Reprocessing the MODIS Leaf Area Index products for land surface and climate modelling, Remote Sensing of Environment, Volume 115, Issue 5, 2011, Pages 1171-1187, ISSN 0034-4257, https://doi.org/10.1016/j.rse.2011.01.001.

It is fetched at 0.05° in NetCDF format via the GriddingMachine.jl package
(datasets `LAI_MODIS_20X_1M_YYYY_V1`):
Y. Wang, P. Köhler, R. K. Braghiere, M. Longo, R. Doughty, A. A. Bloom, and C. Frankenberg. 2022. GriddingMachine, a database and software for Earth system modeling at global and regional scales. Scientific Data. 9: 258. [DOI](https://doi.org/10.1038/s41597-022-01346-x)

Each file contains:
  - `lai` (lon, lat, time): leaf area index of the land part of the cell, m² m⁻².
    It is stored as `Int16` with `scale_factor = 0.001`; NetCDF readers that
    follow the CF conventions (NCDatasets.jl, ClimaUtilities, ClimaAnalysis,
    xarray) unpack it to floats. The source precision is 0.1.
  - `land_fraction` (lon, lat): land fraction of the cell (ETOPO 2022 with
    lakes removed and land below sea level added, see below)
  - `lat`, `lon`: cell centers, degrees north and east
  - `time`: 12 values, 30 days apart starting on January 1 (even spacing is
    required by ClimaLand's `PeriodicCalendar`)

To recreate the artifact, run `julia --project create_artifacts.jl` in this
folder. It downloads 5.8 GB of 0.05° data to `~/GriddingMachine` (removed at the
end), and takes about 10 minutes, mostly downloading.

## Aggregation over land

The 0.05° GriddingMachine data averages the water part of each pixel as LAI = 0
(and then stores LAI = 0 as NaN): a coastal pixel holds about
`land fraction × LAI of its land part`. Its LAI divided by that of the
neighboring fully-land pixels is `-0.07 + 0.94 f`, with `f` the land fraction of
the pixel (vegetated coasts, July 2010). Averaging the pixels with water counted
as 0, which is how the 0.5° GriddingMachine data used by the previous version of
this artifact was built, gives coastal and lake-side cells an LAI that is too
low by their land fraction: for example a 2000-2020 mean of 1.2 instead of
4.0 m² m⁻² in the 1° cell of the GF-Guy FLUXNET site, which is 14% land.

Instead, the LAI of each output cell is

    LAI = Σ a LAI_pixel / Σ a f

over its 0.05° pixels (`land_fraction_correction.jl`), where `a` is the area of
the pixel, `LAI_pixel` its LAI (NaN counted as 0), and `f` its land fraction:
  - `f` is the fraction of the 6 × 6 cells of the 30 arc-second ETOPO 2022
    land-sea mask ([`landsea_mask_30arcseconds`](../landsea_mask)) in the pixel
    that are land;
  - the ETOPO mask counts lakes as land, so a pixel without vegetation in any
    month of 2000-2020 where the 0.1° ERA5 land fraction
    ([`era5_land_fraction`](../era5_land_fraction)) is below 0.5 is a lake
    (`f = 0`);
  - the ETOPO mask floods land below sea level that connects to the sea (the
    Dutch polders, parts of the Nile and Po deltas), so a vegetated pixel with
    an ETOPO land fraction below 0.5 and an ERA5 land fraction of at least 0.9
    is land (`f = 1`): the LAI of such pixels matches that of their fully-land
    neighbors;
  - pixels that MODIS sees as vegetated in some month count as at least half
    land (`f ≥ 0.5`): the MODIS and ETOPO coastlines differ by up to a pixel,
    and dividing by a smaller fraction blows up on small islands;
  - the land fractions are the same for all years, so they do not add
    interannual variability.

Cells without water get the plain average of their pixels. Cells whose only
land is lakes get LAI = 0. Ocean cells are filled from the nearest cells, one
ring of cells at a time, so that interpolating near a coastline never samples
water; use `land_fraction` to mask them when needed.

2000-2020 mean LAI of the previous version of this artifact (0.5° data with
water counted as 0, averaged to 1°) relative to the 0.05° data aggregated over
land to 1°, by land fraction of the cell (cells with a mean LAI above 0.05):

| land fraction | cells | previous / new, quartiles | ratio of means |
| ------------- | ----- | ------------------------- | -------------- |
| (0, 0.2)      | 1889  | 0.04 0.10 0.20            | 0.16           |
| [0.2, 0.5)    | 992   | 0.38 0.46 0.53            | 0.46           |
| [0.5, 0.8)    | 978   | 0.60 0.68 0.75            | 0.67           |
| [0.8, 0.95)   | 730   | 0.86 0.90 0.93            | 0.89           |
| [0.95, 0.999) | 1010  | 0.98 0.99 1.00            | 0.98           |
| [0.999, 1]    | 10254 | 1.00 1.00 1.00            | 1.00           |

## Limitations

- Lakes smaller than a 0.05° pixel are not detected: pixels partly covered by
  lakes stay diluted, so in lake districts (Finland, Canadian Shield) the LAI
  is likely too low by up to the lake fraction of the cell (about 10%).
- Land below sea level is recovered only where ERA5 sees land at 0.1°;
  elsewhere its vegetated pixels count as half land, so their LAI can be up to
  twice too high.
- The LAI of a cell that is mostly water is that of its actual shoreline
  (beaches, mangroves, mudflats, bare reefs), which can differ from the
  vegetation inland.

The previous version of this artifact is the 1° `modis_lai` artifact with
`git-tree-sha1 = "81d4bc1b22e94d66eec3d80a2d21b5dd5303bf8f"` (see
`OutputArtifacts.toml`).

License: Creative Commons Zero
