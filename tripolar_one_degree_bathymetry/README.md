# tripolar_one_degree_bathymetry

ETOPO bathymetry regridded onto the 360 × 180 tripolar grid ClimaCoupler uses by default.

## Source

`NumericalEarth.DataWrangling.ETOPO.ETOPO2022`, regridded by
`NumericalEarth.Bathymetry.regrid_bathymetry`.

## Contents

`tripolar_one_degree_bathymetry.nc`:

- `bottom_height` (m) — negative downwards, minor basins removed

Observed: ocean depths −8960.1 to −10.0 m (the shallow end set by `minimum_depth`), land fraction
0.373.

## Regridding parameters

These are recorded as global attributes and **validated** by ClimaCoupler rather than applied — a
caller asking for different values gets a clear error rather than silently different bathymetry:

- `minimum_depth = 10`
- `major_basins = 2`
- `interpolation_passes = 10`

They match the defaults in ClimaCoupler's `ext/ClimaCouplerCMIPExt/oceananigans.jl`. Changing any of
them means
regenerating this artifact.

## Grid independence

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

## Publishing status

`OutputArtifacts.toml` carries the `git-tree-sha1` and the tarball `sha256`, but `url` is still
`REPLACE_WITH_UPLOAD_URL`: the archive `tripolar_one_degree_bathymetry_artifact.tar.gz` in this directory has not been
uploaded to the Caltech Box yet. Until it is, the entry resolves only from a local Julia artifact
store. Upload the archive, take the `/shared/static/` direct-download link — a `/s/` preview link
serves HTML and fails the hash check — and put it in place of the placeholder. `git-tree-sha1` is a
content hash and does not depend on where the tarball is hosted.
