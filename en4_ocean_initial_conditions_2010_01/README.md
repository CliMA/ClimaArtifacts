# en4_ocean_initial_conditions_2010_01

EN4 monthly ocean temperature and salinity for January 2010, inpainted, on EN4's native
longitude–latitude–depth grid.

## Source

`NumericalEarth.DataWrangling.EN4.EN4Monthly`, date 2010-01-01, variables `temperature` and
`salinity`. NumericalEarth downloads the Met Office EN4 monthly objective analysis.

## Contents

`en4_ocean_initial_conditions_2010_01.nc`, a 360 × 173 × 42 grid:

- `temperature` (°C) and `salinity` (g/kg), inpainted
- `longitude`, `latitude`, `z` — cell centres, for inspection
- `longitude_interfaces`, `latitude_interfaces`, `z_interfaces` — what the reader uses

Observed ranges: temperature −4.00 to 30.78 °C, salinity 4.57 to 40.79 g/kg, longitude 1 to 360,
latitude −83 to 89, z −5350.3 to −5.0 m.

## Why the native grid

Storing the fields on their own grid rather than on a model grid means one artifact serves every
ocean grid ClimaCoupler runs, and changing `Nz`, `depth` or `zstar` needs no new artifact.
ClimaCoupler rebuilds this `LatitudeLongitudeGrid` from the stored interfaces and hands it to
Oceananigans' `interpolate!`.

The interfaces are stored, not just the centres, because they are what determines the grid. A
periodic axis reports only N face nodes, so the script appends the closing interface to give the N+1
a grid expects.

## Inpainting

`NearestNeighborInpainting(Inf)`, NumericalEarth's default for temperature and salinity, is applied
on the native grid before writing. This is the expensive, hard-to-reproduce step, and baking it is
what lets ClimaCoupler do plain interpolation with no land-masking. The script asserts no NaNs
remain.

## Accuracy

ClimaCoupler's `test/artifact_parity/ocean_initial_conditions_parity.jl` compares interpolation from
this artifact against NumericalEarth's `set!(field, metadatum)` on the one-degree tripolar grid:
maximum absolute difference 2.7e-4 °C for temperature and 2.1e-4 g/kg for salinity, with global means
agreeing to roughly 1e-9 relative. The two paths are not bit-identical because they interpolate the
same inpainted native field through separate code.

## Regenerating

```
cd en4_ocean_initial_conditions_2010_01
julia --project=. create_artifact.jl
```

The script writes `en4_ocean_initial_conditions_2010_01_artifact/en4_ocean_initial_conditions_2010_01.nc`
and then hands it to `create_artifact_guided`, which archives it and walks through the upload.

Generated with the versions pinned in this directory's `Project.toml` and `Manifest.toml`:
ClimaOcean 0.10.0, NumericalEarth 0.6.0, Oceananigans 0.110.12. The pins are exact (`=`) so the
artifact stays reproducible as those packages move on.

To add another date, copy this directory, change `start_date`, and add the date to
`supported_initial_condition_dates` in ClimaCoupler's
`ext/ClimaCouplerCMIPExt/ocean_data_artifacts.jl`.

## Publishing status

`OutputArtifacts.toml` carries the `git-tree-sha1` and the tarball `sha256`, but `url` is still
`REPLACE_WITH_UPLOAD_URL`: the archive `en4_ocean_initial_conditions_2010_01_artifact.tar.gz` in this directory has not been
uploaded to the Caltech Box yet. Until it is, the entry resolves only from a local Julia artifact
store. Upload the archive, take the `/shared/static/` direct-download link — a `/s/` preview link
serves HTML and fails the hash check — and put it in place of the placeholder. `git-tree-sha1` is a
content hash and does not depend on where the tarball is hosted.
