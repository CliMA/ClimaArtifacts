# MODIS maximum LAI

This artifact contains the max Leaf Area Index (LAI) derived
from the MODIS LAI data (2000-2020) at 1° × 1° global grid

## Source Data

The max LAI is computed from the yearly MODIS LAI files in the `modis_lai`
artifact, which repackages data from:

Hua Yuan, Yongjiu Dai, Zhiqiang Xiao, Duoying Ji, Wei Shangguan, Reprocessing
the MODIS Leaf Area Index products for land surface and climate modelling,
Remote Sensing of Environment, Volume 115, Issue 5, 2011, Pages 1171-1187,
ISSN 0034-4257, https://doi.org/10.1016/j.rse.2011.01.001.

## Usage

```julia
using ClimaUtilities.ClimaArtifacts
lai_file = joinpath(@clima_artifact("modis_lai_climatology"), "modis_max_lai.nc")
```

## License

Creative Commons Zero (same as source data)
