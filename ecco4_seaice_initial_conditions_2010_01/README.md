# ecco4_seaice_initial_conditions_2010_01

ECCO4 monthly sea-ice concentration and thickness for January 2010, on ECCO4's native
longitude–latitude grid.

## Source

The raw January 2010 files `SIarea_2010_01.nc` and `SIheff_2010_01.nc`, read through
`NumericalEarth.DataWrangling.ECCO.ECCO4Monthly`.

They are taken from the already-published `ecco4_SIarea_SIheff_2010_01` artifact rather than from
`ecco.jpl.nasa.gov`. That artifact holds exactly these two files, so sourcing from it makes this
script runnable without `ECCO_USERNAME` or `ECCO_WEBDAV_PASSWORD` and without access to JPL, which is
not reachable from all networks. The script resolves it through the sibling directory's
`OutputArtifacts.toml`.

## Contents

`ecco4_seaice_initial_conditions_2010_01.nc`, a 720 × 360 grid:

- `sea_ice_concentration` (dimensionless, 0 to 1) and `sea_ice_thickness` (m)
- `longitude`, `latitude` — cell centres, for inspection
- `longitude_interfaces`, `latitude_interfaces` — what the reader uses

Observed: concentration 0 to 0.97, thickness 0 to 4.535 m, ice-covered fraction (concentration above
1%) 0.133.

## Inpainting

None — deliberately. `NumericalEarth.DataWrangling.default_inpainting` returns `nothing` for
`:sea_ice_concentration` and `:sea_ice_thickness`, because land carrying zero ice is a meaningful
value rather than a gap. This artifact reproduces that. The fields are still gap-free, which is what
the reader requires, and the script asserts no NaNs.

The values are written through untouched. The script asserts that concentration lies in `[0, 1]` and
thickness in `[0, ∞)`, and records the observed ranges in the `concentration_range` and
`thickness_range` global attributes. Enforcing the bounds by assertion rather than by clamping means
ECCO4 data that violates them stops the build instead of being silently corrected.

## Accuracy

ClimaCoupler's `test/artifact_parity/ocean_initial_conditions_parity.jl` compares interpolation from
this artifact against NumericalEarth's `set!(field, metadatum)` on the one-degree tripolar grid:
maximum absolute difference 2.5e-5 for concentration and 5.2e-5 m for thickness, with global means
agreeing to roughly 1e-8 relative.

That comparison runs on a static vertical grid because NumericalEarth's `set!` cannot place a
two-dimensional `(Center, Center, Nothing)` field on a mutable z-star grid — `interpolate_physical!`
calls `rnode` with `LZ = Nothing`. ClimaCoupler's reader has no such restriction and is exercised on
the mutable grid in the same test.

## Regenerating

```
cd ecco4_seaice_initial_conditions_2010_01
julia --project=. create_artifact.jl
```

The script writes
`ecco4_seaice_initial_conditions_2010_01_artifact/ecco4_seaice_initial_conditions_2010_01.nc` and then
hands it to `create_artifact_guided`, which archives it and walks through the upload.

Generated with the versions pinned in this directory's `Project.toml` and `Manifest.toml`:
ClimaOcean 0.10.0, NumericalEarth 0.6.0, Oceananigans 0.110.12. The pins are exact (`=`) so the
artifact stays reproducible as those packages move on.

To add another date, copy this directory, change `start_date`, point it at raw ECCO files for that
date, and add the date to `supported_initial_condition_dates` in ClimaCoupler's
`ext/ClimaCouplerCMIPExt/ocean_data_artifacts.jl`.

## Publishing status

`OutputArtifacts.toml` carries the `git-tree-sha1` and the tarball `sha256`, but `url` is still
`REPLACE_WITH_UPLOAD_URL`: the archive `ecco4_seaice_initial_conditions_2010_01_artifact.tar.gz` in this directory has not been
uploaded to the Caltech Box yet. Until it is, the entry resolves only from a local Julia artifact
store. Upload the archive, take the `/shared/static/` direct-download link — a `/s/` preview link
serves HTML and fails the hash check — and put it in place of the placeholder. `git-tree-sha1` is a
content hash and does not depend on where the tarball is hosted.
