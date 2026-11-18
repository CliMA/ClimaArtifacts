# Tripolar bathymetry (from ETOPO2022)

ETOPO bathymetry regridded onto the tripolar grids ClimaCoupler uses. This collection holds one
artifact per resolution:

| Artifact | Grid | File |
|---|---|---|
| `tripolar_one_degree_bathymetry` | 360 × 180 | `tripolar_one_degree_bathymetry.nc` |
| `tripolar_half_degree_bathymetry` | 720 × 360 | `tripolar_half_degree_bathymetry.nc` |
| `tripolar_quarter_degree_bathymetry` | 1440 × 720 | `tripolar_quarter_degree_bathymetry.nc` |

Each file is named after its artifact, so a reader finds it with
`joinpath(@clima_artifact(name), name * ".nc")`.

## Source

ETOPO 2022 (see citation below) via `NumericalEarth.DataWrangling.ETOPO.ETOPO2022` and regridded by
`NumericalEarth.Bathymetry.regrid_bathymetry`.

## Contents

Every file holds:

- `bottom_height` (m) — negative downwards, minor basins removed

Observed:

- one degree: ocean depths −8960.1 to −10.0 m (the shallow end set by `minimum_depth`), land
  fraction 0.373
- half degree: fill in after generation (the script prints the ocean depth range and land fraction)
- quarter degree: fill in after generation

## Regridding parameters

The same for every resolution:

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
cd tripolar_bathymetry
julia --project=. create_artifact.jl                 # every resolution not yet in OutputArtifacts.toml
julia --project=. create_artifact.jl half quarter    # only the named resolutions
```

For each resolution, the script writes `<artifact>_artifact/<artifact>.nc` and then hands it to
`create_artifact_guided`, which archives it, walks through the upload and appends the entry to
`OutputArtifacts.toml`. Resolutions already in `OutputArtifacts.toml` are skipped; delete an entry to
regenerate it.

Generated with the versions pinned in this directory's `Project.toml` and `Manifest.toml`:
ClimaOcean 0.10.0, NumericalEarth 0.6.0, Oceananigans 0.110.12. The pins are exact (`=`) so the
artifacts stay reproducible as those packages move on.

`regrid_bathymetry` caches its result in a Julia scratchspace, so a rerun after the first is fast.

## Citation

NOAA National Centers for Environmental Information. 2022: ETOPO 2022 60 Arc-Second Global Relief
Model. NOAA National Centers for Environmental Information. https://doi.org/10.25921/fd45-gt74

`NumericalEarth.DataWrangling.ETOPO.ETOPO2022` fetches the ice-surface file

No LICENSE file accompanies these artifacts; ETOPO 2022 is a work of the U.S. Government produced by
NOAA NCEI and is distributed without licence restrictions.
