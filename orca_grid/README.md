# ORCA grids (eORCA1, eORCA05, eORCA025)

NEMO eORCA horizontal meshes and their bathymetry in a form ClimaCoupler reads. This collection
holds one artifact per resolution:

| Artifact | Mesh | Stored size | North fold | File |
|---|---|---|---|---|
| `orca_one_grid` | eORCA1 | 360 × 296 | F pivot, `RightFaceFolded` | `orca_one_grid.nc` |
| `orca_half_grid` | eORCA05 | 720 × 535 | F pivot, `RightFaceFolded` | `orca_half_grid.nc` |
| `orca_quarter_grid` | eORCA025 | 1440 × 1051 | T pivot, `RightCenterFolded` | `orca_quarter_grid.nc` |

Each file is named after its artifact, so a reader finds it with
`joinpath(@clima_artifact(name), name * ".nc")`. The fold differs between resolutions, so the reader
must take it from the `topology` and `north_fold_pivot` attributes rather than assume one.

## Sources

**eORCA1**, Zenodo record [4436658](https://zenodo.org/records/4436658), downloaded by
`NumericalEarth.DataWrangling.ORCA.ORCAOne`:

- `eORCA1.2_mesh_mask.nc` — staggered mesh coordinates and scale factors
- `eORCA_R1_bathy_meter_v2.2.nc` — bathymetry in metres

**eORCA05**, Zenodo record [13385024](https://zenodo.org/records/13385024):

- `eORCA05.L75_domain_cfg.nc` — staggered mesh coordinates, scale factors and the bathymetry
  (`bathy_meter`, in metres)

NumericalEarth has no half-degree ORCA dataset, so `create_artifact.jl` defines `ORCAHalf`, which
extends `NumericalEarth.DataWrangling.ORCA` to download this file and read it with
`NumericalEarth.Bathymetry.ORCAGrid`. The file carries every staggered NEMO variable (`glamt/u/v/f`,
`gphit/u/v/f`, `e1*`, `e2*`), so the metrics are read directly; cell areas are `e1 * e2`, since the
file has no `e1e2*` variables. The mesh has `jperio = 6`, an F-point north fold as in eORCA1. The
first 78 rows of the native 722 × 604 mesh are land; `default_south_rows_to_remove(::ORCAHalf) = 68`
removes all but 10 of them, the same latitude span as the 5-row land margin NumericalEarth leaves on
eORCA1.

**eORCA025**, Zenodo record [15494369](https://zenodo.org/records/15494369), downloaded by
`NumericalEarth.DataWrangling.ORCA.ORCAQuarter`:

- `grid_mask_eORCA025-GO6.nc` — T- and F-point coordinates (`glamt`, `gphit`, `glamf`, `gphif`)
- `bathy_eORCA025_noclosea_from_GEBCO2021_S21TT_CloseaCopy_edit.nc` — GEBCO 2021 bathymetry in metres

The eORCA025 metrics are **reconstructed**. The grid file holds only T and F coordinates (in
`Float32`), so `ORCAGrid` derives the U/V coordinates from spherical midpoints, `Δx`/`Δy` from
haversine distances and `Az` from spherical quadrilateral areas. They approximate the scale factors
NEMO itself uses on this grid. The stored 1440 × 1051 mesh is the 1442 × 1207 native one less the
periodic overlap, the 155 southern land rows NumericalEarth removes, and the fold row.

## Contents

Every file holds:

- 20 metric arrays — `λ`, `φ`, `Δx`, `Δy` and `Az` at the `ᶜᶜ`, `ᶠᶜ`, `ᶜᶠ` and `ᶠᶠ` stagger positions,
  under ASCII names (`lambda_cca`, `phi_fca`, `dx_cfa`, `area_ffa`, …) since NetCDF does not carry the
  Unicode sub/superscripts portably. Each variable records its Oceananigans name and stagger location
  as attributes.
- `bottom_height` — negative downwards, minor basins removed, land carrying the sentinel `100`.
- Global attributes `Nx`, `Ny`, `radius`, `north_poles_latitude`, `first_pole_longitude`,
  `southernmost_latitude` and `topology`, which reconstruct the `Tripolar` conformal mapping, and
  `north_fold_pivot`. The published `orca_one_grid` predates this collection and lacks
  `north_fold_pivot`; its `topology` is `Periodic, RightFaceFolded, Bounded`.

Observed: eORCA1 ocean depths reach −7660 m. Fill in eORCA05 and eORCA025 after generation (the
script prints the ocean depth range and land fraction).

## Three things the reader depends on

**Halos are not stored.** The metrics are written at interior size and ClimaCoupler fills the halos
with `Oceananigans.BoundaryConditions.fill_halo_regions!`, which resolves the periodic east/west fill
and the north fold from the topology. This keeps `halo` a free argument.

**The Face-in-y extent follows the fold.** Under `RightFaceFolded` (eORCA1, eORCA05) a Face-in-y
metric has Ny+1 rows (297 and 536), one more than a Center-in-y one, hence the separate `y_face`
dimension. The extra row is the fold row, which `fill_halo_regions!` cannot reconstruct. Under
`RightCenterFolded` (eORCA025) the extents match and `y_face` is unused; it is used only where it
differs from `Ny`.

**The bathymetry is not snapped.** `GridFittedBottom` snaps the bottom onto vertical cell interfaces
and clamps it to the vertical domain, so taking `bottom_height` from a constructed
`ImmersedBoundaryGrid` would bake the generation-time `Nz` and `depth` into the artifact. This script
stops short of `GridFittedBottom`, letting ClimaCoupler discretize against the grid it runs with.
Ocean depths therefore go deeper than the generation depth.

## Regenerating

```
cd orca_grid
julia --project=. create_artifact.jl                 # every resolution not yet in OutputArtifacts.toml
julia --project=. create_artifact.jl half quarter    # only the named resolutions
```

On first run the script downloads ~1 GB (eORCA1), ~90 MB (eORCA05) or ~50 MB (eORCA025). For each
resolution it writes `<artifact>_artifact/<artifact>.nc` and then hands it to
`create_artifact_guided`, which archives it, walks through the upload and appends the entry to
`OutputArtifacts.toml`. Resolutions already in `OutputArtifacts.toml` are skipped; delete an entry to
regenerate it.

Generated with the versions pinned in this directory's `Project.toml` and `Manifest.toml`:
NumericalEarth 0.8.2, Oceananigans 0.113.6. `major_basins = 2`. The pins are exact (`=`) so the
artifacts stay reproducible as those packages move on. `ORCAHalf` extends internal NumericalEarth
functions (`ORCA.mesh_mask_url`, `ORCA.bathymetry_url`, `ORCA.north_fold_pivot`,
`ORCA.default_south_rows_to_remove`), so moving the pin needs a check that they still exist.

## Citation

**eORCA1**: Deshayes, J., Ethé, C., Mignot, J., & Lévy, C. (2021). *Full information on the eORCA1
grid (mesh_mask) used in IPSL-CM6A-LR configuration* [Data set]. Zenodo.
https://doi.org/10.5281/zenodo.4436658. The grid is the one used in the NEMO v3.6_STABLE ocean
component of IPSL-CM6A-LR.

**eORCA05**: Albert, A. (2024). *Configuration files for extended global ORCA grid at 1/2° resolution
and 75 vertical levels (eORCA05.L75)* [Data set]. Zenodo. https://doi.org/10.5281/zenodo.13385024.
The inputs and DOMAINcfg namelists used to build the `domain_cfg` are in Zenodo record
[14361713](https://doi.org/10.5281/zenodo.14361713).

**eORCA025**: Storkey, D. (2025). *Ocean model bathymetry on eORCA025 grid derived from GEBCO2021*
(1.0.0) [Data set]. Zenodo. https://doi.org/10.5281/zenodo.15494369. The bathymetry processing is
documented at https://github.com/JMMP-Group/GLOBAL_BATHYMETRY/releases/tag/v1.0.0. That release notes
an unrealistic plateau in the Caspian Sea bathymetry, which `major_basins = 2` removes along with the
other disconnected basins. GEBCO Compilation Group (2021). GEBCO 2021 Grid.
https://doi.org/10.5285/c6612cbe-50b3-0cff-e053-6c86abc09f8f

See https://www.nemo-ocean.eu/wp-content/uploads/NEMO_book.pdf for the NEMO grid description.

## License

**eORCA1 and eORCA05**: Creative Commons Attribution 4.0 International (CC BY 4.0), the license
attached to Zenodo records 4436658 and 13385024, reproduced in `LICENSE`. Attribution as above is
required. CC BY 4.0 permits the adaptation made here: the mesh metrics are carried through unchanged
apart from removing the periodic overlap, the southern land rows and the fold row, while the
bathymetry is sign-flipped to negative-downwards and has minor basins removed (`major_basins = 2`).

**eORCA025**: TODO. Zenodo record 15494369 lists no license, and the GLOBAL_BATHYMETRY repository's
CeCILL v2 license covers its code. Confirm the terms for the data with the authors (Met Office) before
uploading `orca_quarter_grid`, and record them here once they are known.
