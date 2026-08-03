# tripolar_one_degree_bathymetry

ETOPO bathymetry regridded onto the 360 × 180 tripolar grid ClimaCoupler uses.

## Source

ETOPO 2022 (see citation below) via `NumericalEarth.DataWrangling.ETOPO.ETOPO2022` and regridded by
`NumericalEarth.Bathymetry.regrid_bathymetry`.

## Contents

`tripolar_one_degree_bathymetry.nc`:

- `bottom_height` (m) — negative downwards, minor basins removed

Observed: ocean depths −8960.1 to −10.0 m (the shallow end set by `minimum_depth`), land fraction
0.373.

## Regridding parameters

- `minimum_depth = 10`
- `major_basins = 2`
- `interpolation_passes = 10`

The regridding is horizontal, so the vertical grid does not affect the result; the `Nz` and `depth`
used during generation are supplied only because `TripolarGrid` requires them.

The stored bottom height is **not snapped** to vertical cell interfaces. `GridFittedBottom` does that
at load time against whatever vertical grid ClimaCoupler runs with, so `Nz`, `depth` and `zstar`
remain free.

## Regenerating

```
cd tripolar_one_degree_bathymetry
julia --project=. create_artifact.jl
```

The script writes `tripolar_one_degree_bathymetry_artifact/tripolar_one_degree_bathymetry.nc` and then
hands it to `create_artifact_guided`, which archives it and walks through the upload.

Generated with the versions pinned in this directory's `Project.toml` and `Manifest.toml`:
ClimaOcean 0.10.0, NumericalEarth 0.6.0, Oceananigans 0.110.12. The pins are exact (`=`) so the
artifact stays reproducible as those packages move on.

`regrid_bathymetry` caches its result in a Julia scratchspace, so a rerun after the first is fast.

## Citation

NOAA National Centers for Environmental Information. 2022: ETOPO 2022 60 Arc-Second Global Relief
Model. NOAA National Centers for Environmental Information. https://doi.org/10.25921/fd45-gt74

`NumericalEarth.DataWrangling.ETOPO.ETOPO2022` fetches the ice-surface file

No LICENSE file accompanies this artifact; ETOPO 2022 is a work of the U.S. Government produced by
NOAA NCEI and is distributed without licence restrictions.
