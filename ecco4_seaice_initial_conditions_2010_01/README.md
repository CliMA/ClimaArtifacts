# ecco4_seaice_initial_conditions_2010_01

ECCO4 monthly sea-ice concentration and thickness for January 2010, on ECCO4's native
longitude–latitude grid, packaged in a way that ClimaCoupler can ingest.

## Source

The raw January 2010 files `SIarea_2010_01.nc` and `SIheff_2010_01.nc` from the already-published 
`ecco4_SIarea_SIheff_2010_01` artifact.

## Contents

`ecco4_seaice_initial_conditions_2010_01.nc`, a 720 × 360 grid:

- `sea_ice_concentration` (dimensionless, 0 to 1) and `sea_ice_thickness` (m)
- `longitude`, `latitude` — cell centers, for inspection
- `longitude_interfaces`, `latitude_interfaces` — what the reader uses

Observed: concentration 0 to 0.97, thickness 0 to 4.535 m, ice-covered fraction (concentration above
1%) 0.133.

## Inpainting

None. `NumericalEarth.DataWrangling.default_inpainting` returns `nothing` for
`:sea_ice_concentration` and `:sea_ice_thickness`, because land carrying zero ice is a meaningful
value rather than a gap. The fields are still gap-free, which is what
the reader requires, and the script asserts no NaNs.

The values are written through untouched. The script asserts that concentration lies in `[0, 1]` and
thickness in `[0, ∞)`, and records the observed ranges in the `concentration_range` and
`thickness_range` global attributes.

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
date.

## Citation

*ECCO Consortium, Fukumori, I., Wang, O., Fenty, I., Forget, G., Heimbach, P., & Ponte, R. M. (May
14, 2026). ECCO Central Estimate (Version 4 Release 4). Retrieved from
https://ecco.jpl.nasa.gov/drive/files/Version4/Release4/interp_monthly/SIarea/2010/SIarea_2010_01.nc
and
https://ecco.jpl.nasa.gov/drive/files/Version4/Release4/interp_monthly/SIheff/2010/SIheff_2010_01.nc.*

See https://ecco-group.org/products-ECCO-V4r4.htm for the product description.

No LICENSE file accompanies this artifact; ECCO V4r4 is distributed as open data by NASA/JPL.
