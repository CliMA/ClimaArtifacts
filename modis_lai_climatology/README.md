# MODIS LAI Monthly Climatology

This artifact contains a monthly climatology of Leaf Area Index (LAI) derived
from the MODIS LAI data (2000-2020).

## Source Data

The climatology is computed from the yearly MODIS LAI files in the `modis_lai`
artifact, which repackages data from:

Hua Yuan, Yongjiu Dai, Zhiqiang Xiao, Duoying Ji, Wei Shangguan, Reprocessing
the MODIS Leaf Area Index products for land surface and climate modelling,
Remote Sensing of Environment, Volume 115, Issue 5, 2011, Pages 1171-1187,
ISSN 0034-4257, https://doi.org/10.1016/j.rse.2011.01.001.

## Processing

For each month, the climatology is computed by averaging LAI values across all
years (2000-2020). The time coordinate uses uniform 30-day spacing starting
from 2000-01-01, which is compatible with ClimaLand's `PeriodicCalendar`
boundary condition.

## Output Format

A single NetCDF file `modis_lai_climatology.nc` with:
  - `lai`  : Leaf area index climatology, m² m⁻²
  - `lat`  : Latitude, degrees north
  - `lon`  : Longitude, degrees east
  - `time` : Month of year (12 values with 30-day uniform spacing)

Resolution: 1° × 1° global grid

## Usage

```julia
using ClimaUtilities.ClimaArtifacts
lai_file = joinpath(@clima_artifact("modis_lai_climatology"), "modis_lai_climatology.nc")
```

## License

Creative Commons Zero (same as source data)
