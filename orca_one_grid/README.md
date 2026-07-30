# orca_one_grid

The eORCA1 (NEMO) horizontal mesh and its bathymetry, in a form ClimaCoupler reads without
NumericalEarth or ClimaOcean.

## Source

Zenodo record [4436658](https://zenodo.org/records/4436658):

- `eORCA1.2_mesh_mask.nc` — staggered mesh coordinates and scale factors
- `eORCA_R1_bathy_meter_v2.2.nc` — bathymetry in metres

Both are downloaded by `NumericalEarth.DataWrangling.ORCA.ORCAOne`.

## Contents

`orca_one_grid.nc`, a 362 × 297 mesh:

- 20 metric arrays — `λ`, `φ`, `Δx`, `Δy` and `Az` at the `ᶜᶜ`, `ᶠᶜ`, `ᶜᶠ` and `ᶠᶠ` stagger positions,
  under ASCII names (`lambda_cca`, `phi_fca`, `dx_cfa`, `area_ffa`, …) since NetCDF does not carry the
  Unicode sub/superscripts portably. Each variable records its Oceananigans name and stagger location
  as attributes.
- `bottom_height` — negative downwards, minor basins removed, land carrying the sentinel `100`.
- Global attributes `Nx`, `Ny`, `radius`, `north_poles_latitude`, `first_pole_longitude`,
  `southernmost_latitude`, which reconstruct the `Tripolar` conformal mapping.

## Two things the reader depends on

**Halos are not stored.** The metrics are written at interior size and ClimaCoupler fills the halos
with `Oceananigans.BoundaryConditions.fill_halo_regions!`, which resolves the periodic east/west fill
and the north fold from the `(Periodic, RightFaceFolded, Bounded)` topology. This keeps `halo` a free
argument. ClimaCoupler's `test/artifact_parity/orca_one_grid_parity.jl` confirms the reconstructed
metrics are bit-identical to `ORCAGrid`'s, halos included.

**Face-in-y metrics have Ny+1 = 298 rows**, one more than the Center-in-y ones, hence the separate
`y_face` dimension. Storing only Ny rows drops the fold row, which `fill_halo_regions!` cannot
reconstruct.

**The bathymetry is not snapped.** `GridFittedBottom` snaps the bottom onto vertical cell interfaces
and clamps it to the vertical domain, so taking `bottom_height` from a constructed
`ImmersedBoundaryGrid` would bake the generation-time `Nz` and `depth` into the artifact. This script
stops short of `GridFittedBottom`, letting ClimaCoupler discretize against the grid it actually runs
with. Ocean depths therefore reach −7660 m rather than being cut off at the generation depth.

## Regenerating

```
cd orca_one_grid
julia --project=. create_artifact.jl
```

The script writes `orca_one_grid_artifact/orca_one_grid.nc` and then hands it to
`create_artifact_guided`, which archives it and walks through the upload.

Generated with the versions pinned in this directory's `Project.toml` and `Manifest.toml`:
ClimaOcean 0.10.0, NumericalEarth 0.6.0, Oceananigans 0.110.12. `major_basins = 2`. The pins are
exact (`=`) so the artifact stays reproducible as those packages move on.

Parity against NumericalEarth is checked from ClimaCoupler, by
`test/artifact_parity/orca_one_grid_parity.jl`, since it exercises ClimaCoupler's reader.

Note that `ORCAOne` is the current dataset name in NumericalEarth 0.6.0; ClimaOcean 0.10.0 still
imports the older `ORCA1`, which no longer exists, so the script calls `ORCAGrid` directly.

## Publishing status

`OutputArtifacts.toml` carries the `git-tree-sha1` and the tarball `sha256`, but `url` is still
`REPLACE_WITH_UPLOAD_URL`: the archive `orca_one_grid_artifact.tar.gz` in this directory has not been
uploaded to the Caltech Box yet. Until it is, the entry resolves only from a local Julia artifact
store. Upload the archive, take the `/shared/static/` direct-download link — a `/s/` preview link
serves HTML and fails the hash check — and put it in place of the placeholder. `git-tree-sha1` is a
content hash and does not depend on where the tarball is hosted.
