# en4_ocean_initial_conditions_2010_01

EN4 monthly ocean temperature and salinity for January 2010, inpainted, on EN4's native
longitude–latitude–depth grid.

## Source

Met Office EN4 monthly objective analysis data (via `NumericalEarth.DataWrangling.EN4.EN4Monthly`); date 2010-01-01, 
variables `temperature` and `salinity`.

## Contents

`en4_ocean_initial_conditions_2010_01.nc`, a 360 × 173 × 42 grid:

- `temperature` (°C) and `salinity` (g/kg), inpainted
- `longitude`, `latitude`, `z` — cell centers, for inspection
- `longitude_interfaces`, `latitude_interfaces`, `z_interfaces` — what the reader uses

Observed ranges: temperature −4.00 to 30.78 °C, salinity 4.57 to 40.79 g/kg, longitude 1 to 360,
latitude −83 to 89, z −5350.3 to −5.0 m.

## Why the native grid

Storing the fields on their own grid rather than on a model grid means one artifact serves every
ocean grid ClimaCoupler runs, and changing `Nz`, `depth` or `zstar` needs no new artifact.
ClimaCoupler rebuilds this `LatitudeLongitudeGrid` from the stored interfaces and hands it to
Oceananigans' `interpolate!`.

The interfaces are stored, not just the centers, because they are what determines the grid. A
periodic axis reports only N face nodes, so the script appends the closing interface to give the N+1
a grid expects.

## Inpainting

`NearestNeighborInpainting(Inf)` is applied on the native grid before writing. 

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

To add another date, copy this directory, change `start_date`.

## Citation

Good, S. A., M. J. Martin and N. A. Rayner, 2013. EN4: quality controlled ocean temperature and
salinity profiles and monthly objective analyses with uncertainty estimates, *Journal of Geophysical
Research: Oceans*, doi:10.1002/2013JC009067.

EN.4.2.2 data were obtained from https://www.metoffice.gov.uk/hadobs/en4/ and are © British Crown
Copyright, Met Office, 2026, provided under a Non-Commercial Government Licence
http://www.nationalarchives.gov.uk/doc/non-commercial-government-licence/version/2/

## License

Non-Commercial Government Licence v2.0 (NCGL-UK-2.0), reproduced in `LICENSE`. The license permits
copying, distribution and adaptation for non-commercial purposes only, and requires the attribution
above to travel with the data.
