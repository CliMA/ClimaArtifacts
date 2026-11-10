# Water table depth from Fan et al. (2017)

## Overview

Global annual-mean depth of the water table from Fan et al. (2017), "Hydrologic regulation
of plant rooting depth", PNAS. This is **model output, not a measurement**: the
groundwater–soil–river hydrology model of Miguez-Macho and Fan (2012) was run at 30
arc-seconds (<1 km) and hourly steps over 2003–2013. Fan and Miguez-Macho recommend this
estimate over the earlier equilibrium estimate of Fan et al. (2013), which was biased
shallow (see Method below).

The data is distributed by the Universidade de Santiago de Compostela as five continental
tiles (Africa, Eurasia, North America, Oceania, South America) at
http://thredds-gfnl.usc.es/thredds/catalog/GLOBALWTDFTP/catalog.html. The
`create_artifact.jl` script downloads the annual means (`annualmeans/`, 343 MB) and creates
two artifacts:

| Artifact | File | Content | Size |
|---|---|---|---|
| `fan2017_water_table_depth_30arcseconds` | `fan2017_wtd_annualmean_30arcsec.nc` | `wtd(lon, lat)`, the tiles mosaicked onto one global 43200 × 21600 grid | 300 MB |
| `fan2017_water_table_depth_1degree` | `fan2017_wtd_1deg.nc` | `wtd_mean15(lon, lat)`, the mean over each 1-degree cell of the depth capped at 15 m | 88 kB |

The monthly climatology (`monthlymeans/`, about 4 GB) is not included.

### 30 arc-second file

- `wtd` is the depth of the water table below the land surface in m, **positive downward**:
  0 means the water table is at the surface. The source files store the negative of this
  (`WTD`, from -1000 to 0 m). Here the sign is flipped. Values are otherwise identical,
  except as noted below.
- Cell centers are at `-180 + (i - 0.5)/120` degrees east and `-90 + (j - 0.5)/120`
  degrees north. The tiles lie on this lattice. Their Float32 coordinates drift by up to
  0.1 cell, so they are placed by their first coordinate.
- The tiles do not overlap: no cell is claimed by more than one tile's `mask`. Cells outside
  every tile's `mask` are missing (`_FillValue`). That is the ocean, Antarctica, Greenland,
  Iceland (except a strip east of 14°W), and some islands (e.g., the Azores). In total,
  213,432,897 cells have data.
- `wtd` is packed into Int16 with the source's `scale_factor` (1000/65535) and the
  negated `add_offset`, so the values are on the source's 1.5 cm quantization and range
  from 0 to 1000 m. In the source, every Int16 code is a valid depth, so none is free to
  mark missing cells. To free one for `_FillValue`, 1,134 cells at exactly 1000 m were moved
  to 999.985 m.
- After unpacking, a water table at the surface reads 5.7e-14 rather than exactly 0, so
  compare with a tolerance.
- With `NCDatasets`, `ds["wtd"]` returns `Union{Missing, Float64}`. With
  `ClimaUtilities.SpaceVaryingInput`, replace `missing` through the file reader, e.g.,
  `file_reader_kwargs = (; preprocess_func = x -> coalesce(x, NaN))`. The file reader
  holds the full grid twice, as read and as preprocessed, which takes about 16 GB of
  memory. To compare with a coarse model, prefer an
  aggregate such as the 1-degree file over interpolation, which only samples single 1 km
  cells.

### 1-degree file

`wtd_mean15` is the observation of the water table leaderboard of ClimaLand. It is the
mean over each 1-degree cell of `min(wtd, 15 m)`, taken over the 30 arc-second cells with
data. 15 m is the depth of the ClimaLand soil column, so the result compares with the
grid-mean water table of TOPMODEL. **The 15 m cap is a ClimaLand choice, not part of
Fan et al. (2017).**

Cells are centered on whole degrees (longitudes -180, ..., 179; latitudes -90, ..., 89)
and cover [center - 0.5, center + 0.5). Cells without data are NaN, with no `_FillValue`.
18,141 cells have data.

## Method (Fan et al., 2017, SI Appendix)

- **Model:** each 30 arc-second land column is 1 km deep with 40 layers. The model solves
  the vertical soil water flow (Richards equation), with:
  - a dynamic water table,
  - two-way exchange with rivers and floodplains,
  - lateral groundwater flow between columns,
  - root water uptake that adapts in depth to meet the transpiration demand from satellite
    leaf area index.
- **Run setup:** each continent was run separately with sea level as the lateral boundary
  condition, at 1-hour steps over 2003–2013.
- **Forcing and inputs:**
  - atmosphere from the ERA-Interim reanalysis;
  - precipitation from MSWEP v1.1;
  - topography from SRTM/HydroSHEDS below 60°N;
  - soil from the FAO global harmonized soil database;
  - porosity and permeability decaying exponentially with depth, at a rate set by terrain
    slope (Fan et al., 2013).
- **Spin-up:** the run starts from the equilibrium water table of Fan et al. (2013). The
  11-year run is repeated until long-term drifts vanish.
- **Observations:** the 2017 paper reports no calibration or validation of the water
  table against wells. Observations enter indirectly: the e-folding depth of the
  permeability profile was calibrated by Fan et al. (2013) against water table and wetland
  observations in North America.
- **Limitations stated by the authors:**
  - no crop irrigation;
  - a leaf area climatology (no inter-annual variation);
  - no explicit depth to bedrock.
  The model description does not include groundwater pumping either.
- **Comparison with Fan et al. (2013):** the 2013 estimate used mean annual recharge from
  the top 2 m of soil and ignored lateral convergence, deep root uptake, seasonality and
  incised rivers. According to Fan and Miguez-Macho, all of these biased it shallow. The
  2017 water table is deeper, especially in dry climates and lowlands.
- **Averaging period:** the annual-mean file does not state it. The paper averages its
  results over 2004–2013. The monthly files on the same server give climatology bounds from
  2004-01-01 to 2013-01-01.

## Usage

To recreate the artifacts, run from this directory:

```
julia --project -e 'using Pkg; Pkg.instantiate()'
julia --project create_artifact.jl
```

The script downloads the five tiles if they are not in this directory. It reuses the
output files if they exist, so delete them to regenerate them. It takes a few minutes and
about 5 GB of memory.

## References

Fan Y, Miguez-Macho G, Jobbágy EG, Jackson RB, Otero-Casal C (2017) Hydrologic regulation of
plant rooting depth. Proc Natl Acad Sci USA 114(40):10572–10577.
https://doi.org/10.1073/pnas.1712381114. SI Appendix:
https://ftp.ebi.ac.uk/pub/databases/biostudies/S-EPMC/924/S-EPMC5635924/Files/pnas.1712381114.sapp.pdf

Fan Y, Li H, Miguez-Macho G (2013) Global patterns of groundwater table depth. Science
339:940–943. https://doi.org/10.1126/science.1229881

Miguez-Macho G, Fan Y (2012) The role of groundwater in the Amazon water cycle: 1. Influence
on seasonal streamflow, flooding and wetlands. J Geophys Res 117:D15113.
https://doi.org/10.1029/2012JD017539

Fan Y, Miguez-Macho G (2020) eLetter on Fan et al. (2013), Science, describing the revised
dataset: https://science.sciencemag.org/content/339/6122/940/tab-e-letters (archived at
http://web.archive.org/web/20210225110711/https://science.sciencemag.org/content/339/6122/940/tab-e-letters)

## License

The source files carry the following disclaimer, copied in the artifact files:

> These data can be used freely for research purposes provided that the following source is
> acknowledged: Fan Y, Miguez-Macho G, Jobbágy EG, Jackson RB, Otero-Casal C (2017):
> Hydrologic regulation of plant rooting depth, Proceedings of the National Academy of
> Sciences 114 (40), 10572-10577, doi: 10.1073/pnas.1712381114. These data are made
> available in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the
> implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE
