# orca_grid

NEMO eORCA horizontal meshes and their bathymetry in a form ClimaCoupler reads, one artifact per
resolution:

| Artifact | Mesh | Stored size | North fold |
|---|---|---|---|
| `orca_one_grid` | eORCA1 | 360 × 296 | F pivot, `RightFaceFolded` |
| `orca_half_grid` | eORCA05 | 720 × 535 | F pivot, `RightFaceFolded` |
| `orca_quarter_grid` | eORCA025 | 1440 × 1051 | T pivot, `RightCenterFolded` |

Each artifact holds a single file named after it, read with
`joinpath(@clima_artifact(name), name * ".nc")`. The fold differs between resolutions, so readers take
it from the `topology` and `north_fold_pivot` attributes.

## Sources

- **eORCA1**, Zenodo [4436658](https://zenodo.org/records/4436658), via
  `NumericalEarth.DataWrangling.ORCA.ORCAOne`: `eORCA1.2_mesh_mask.nc` (mesh) and
  `eORCA_R1_bathy_meter_v2.2.nc` (bathymetry).
- **eORCA05**, Zenodo [13385024](https://zenodo.org/records/13385024): `eORCA05.L75_domain_cfg.nc`
  (mesh and `bathy_meter`). NumericalEarth has no half-degree dataset, so `create_artifact.jl` defines
  `ORCAHalf`. Cell areas are `e1 * e2`. Of the 78 southern land rows, 68 are removed, matching the
  latitude span NumericalEarth keeps on eORCA1.
- **eORCA025**, Zenodo [15494369](https://zenodo.org/records/15494369), via
  `NumericalEarth.DataWrangling.ORCA.ORCAQuarter`: `grid_mask_eORCA025-GO6.nc` (T/F coordinates only)
  and `bathy_eORCA025_noclosea_from_GEBCO2021_S21TT_CloseaCopy_edit.nc` (GEBCO 2021 bathymetry). The
  metrics are **reconstructed** from the T/F coordinates (spherical midpoints, haversine distances,
  spherical quadrilateral areas) and approximate NEMO's own scale factors.

## Contents

- 20 metric arrays — `λ`, `φ`, `Δx`, `Δy` and `Az` at the `ᶜᶜ`, `ᶠᶜ`, `ᶜᶠ` and `ᶠᶠ` stagger positions,
  under ASCII names (`lambda_cca`, `phi_fca`, `dx_cfa`, `area_ffa`, …). Each variable records its
  Oceananigans name and stagger location as attributes.
- `bottom_height` — negative downwards, minor basins removed, land carrying the sentinel `100`.
- Global attributes `Nx`, `Ny`, `radius`, `north_poles_latitude`, `first_pole_longitude`,
  `southernmost_latitude`, `topology` and `north_fold_pivot`. The published `orca_one_grid` predates
  this collection and lacks `north_fold_pivot`.

Observed: eORCA1 ocean depths reach −7660 m. Fill in eORCA05 and eORCA025 after generation.

## Three things the reader depends on

**Halos are not stored.** ClimaCoupler fills them with `fill_halo_regions!`, which resolves the
periodic and north-fold boundaries from the topology, so `halo` stays free.

**The Face-in-y extent follows the fold.** Under `RightFaceFolded` (eORCA1, eORCA05) Face-in-y metrics
have Ny+1 rows, stored in the `y_face` dimension; the extra row is the fold row, which
`fill_halo_regions!` cannot reconstruct. Under `RightCenterFolded` (eORCA025) the extents match.

**The bathymetry is not snapped.** The script stops short of `GridFittedBottom`, so the generation-time
`Nz` and `depth` are not baked in and ClimaCoupler discretizes against the grid it runs with.

## Regenerating

```
cd orca_grid
julia --project=. create_artifact.jl                 # every resolution not yet in OutputArtifacts.toml
julia --project=. create_artifact.jl half quarter    # only the named resolutions
```

First runs download ~1 GB (eORCA1), ~90 MB (eORCA05) or ~50 MB (eORCA025). For each resolution the
script writes `<artifact>_artifact/<artifact>.nc` and hands it to `create_artifact_guided`, which
archives it, walks through the upload and appends the entry to `OutputArtifacts.toml`. Resolutions
already listed there are skipped; delete an entry to regenerate it.

Generated with the exact versions pinned in `Project.toml` and `Manifest.toml`: NumericalEarth 0.8.2,
Oceananigans 0.113.6, with `major_basins = 2`. `ORCAHalf` extends internal NumericalEarth functions,
so check they still exist before moving the pin.

## Citation

**eORCA1**: Deshayes, J., Ethé, C., Mignot, J., & Lévy, C. (2021). *Full information on the eORCA1
grid (mesh_mask) used in IPSL-CM6A-LR configuration* [Data set]. Zenodo.
https://doi.org/10.5281/zenodo.4436658

**eORCA05**: Albert, A. (2024). *Configuration files for extended global ORCA grid at 1/2° resolution
and 75 vertical levels (eORCA05.L75)* [Data set]. Zenodo. https://doi.org/10.5281/zenodo.13385024

**eORCA025**: Storkey, D. (2025). *Ocean model bathymetry on eORCA025 grid derived from GEBCO2021*
(1.0.0) [Data set]. Zenodo. https://doi.org/10.5281/zenodo.15494369. GEBCO Compilation Group (2021).
GEBCO 2021 Grid. https://doi.org/10.5285/c6612cbe-50b3-0cff-e053-6c86abc09f8f

See https://www.nemo-ocean.eu/wp-content/uploads/NEMO_book.pdf for the NEMO grid description.

## License

**eORCA1 and eORCA05**: CC BY 4.0, the license of Zenodo records 4436658 and 13385024, reproduced in
`LICENSE`. Attribution as above is required. The mesh metrics are carried through unchanged apart from
removing the periodic overlap, southern land rows and fold row; the bathymetry is sign-flipped and has
minor basins removed.

**eORCA025**: TODO. Zenodo record 15494369 lists no license. Confirm the data terms with the authors
(Met Office) before uploading `orca_quarter_grid`, and record them here.
