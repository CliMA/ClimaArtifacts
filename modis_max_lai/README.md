# MODIS maximum LAI, land part of each cell

This recipe creates the `modis_max_lai_0.25deg` artifact with the maximum leaf
area index (LAI) of the *land part* of each 0.25° grid cell over 2000-2020, in
the file `modis_max_lai_0.25x0.25.nc`: for each cell, the maximum over all
months of the yearly files of the `modis_lai_0.25deg` artifact of the
[`modis_lai`](../modis_lai) recipe.

The yearly files aggregate 0.05° MODIS LAI over land only, since the source
data averages water as LAI = 0; see the [`modis_lai` README](../modis_lai/README.md)
for the method and its validation. Like the yearly files, the maximum LAI is
nonzero over the ocean, extended from the nearest land cells.

## Source data

Hua Yuan, Yongjiu Dai, Zhiqiang Xiao, Duoying Ji, Wei Shangguan, Reprocessing
the MODIS Leaf Area Index products for land surface and climate modelling,
Remote Sensing of Environment, Volume 115, Issue 5, 2011, Pages 1171-1187,
ISSN 0034-4257, https://doi.org/10.1016/j.rse.2011.01.001.

## Output format

The NetCDF file contains, on the grid of the yearly files:
  - `lai` (lon, lat): maximum leaf area index of the land part of the cell,
    m² m⁻², stored as `Int16` with `scale_factor = 0.001` (unpacked by
    CF-compliant readers)
  - `land_fraction` (lon, lat): land fraction of the cell (see the `modis_lai` README)
  - `lon`, `lat`: cell centers, degrees east and north

To recreate the artifact, run `julia --project create_artifact.jl` in this
folder. `Artifacts.toml` gives the download link of its `modis_lai_0.25deg`
source.

## Usage

```julia
using ClimaUtilities.ClimaArtifacts
lai_file = joinpath(@clima_artifact("modis_max_lai_0.25deg"), "modis_max_lai_0.25x0.25.nc")
```

## License

Creative Commons Zero (same as source data)
