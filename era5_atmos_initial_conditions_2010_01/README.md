# ERA5 atmospheric initial condition for 1 January 2010

This artifact holds one file, `era5_init_processed_internal_20100101_0000.nc` (493 MB): the ERA5 atmospheric state at
2010-01-01 00:00 UTC in the form read by the `WeatherModel` initial condition of
[ClimaAtmos](https://github.com/CliMA/ClimaAtmos.jl), for example by ClimaCoupler runs that start on that date. It is
small enough to be downloaded, unlike the `wxquest_initial_conditions` artifact it comes from.

The file contains, on a 384 × 192 longitude-latitude grid (about 0.94°) and 467 altitude levels from 0 to 69.9 km
every 150 m:

- `u`, `v`: eastward and northward wind (m s⁻¹)
- `w`: vertical velocity (m s⁻¹), converted from ERA5's pressure velocity
- `t`: temperature (K)
- `q`: specific humidity (kg kg⁻¹)
- `p_3d`: pressure (Pa)
- `z_physical`: altitude of each level (m)
- `p`: surface pressure (Pa), `skt`: skin temperature (K) and `z_sfc`: surface altitude (m), surface fields repeated
  on every level

## Processing

The file is the one of the same name in the
[`wxquest_initial_conditions`](https://github.com/CliMA/ClimaArtifacts/tree/main/wxquest_initial_conditions)
artifact, whose recipe downloads ERA5 model-level data from the Copernicus Climate Data Store and interpolates it to
the grid above. Values and attributes are copied unchanged. `create_artifact.jl` rewrites the file with `nccopy` from
NetCDF_jll, using byte shuffling and deflate level 4 in chunks spanning whole columns (467 × 16 × 16). This reduces it
from 1.3 GB to 493 MB, mostly because the surface fields stored on every level compress away. The script then checks
that every variable and attribute matches the input.

To recreate the artifact, make the `wxquest_initial_conditions` artifact available (through an `Overrides.toml`, or by
pointing `WXQUEST_INITIAL_CONDITIONS_DIR` at a folder holding its 2010-01-01 file) and run

```bash
cd era5_atmos_initial_conditions_2010_01
julia --project create_artifact.jl
```

## Reference

Hersbach, H., Bell, B., Berrisford, P., et al. (2020): The ERA5 global reanalysis. Quarterly Journal of the Royal
Meteorological Society, 146, 1999–2049, DOI: [10.1002/qj.3803](https://doi.org/10.1002/qj.3803)

## Licence

Contains modified Copernicus Climate Change Service information (2026). Please see the
[License to Use Copernicus Products](https://object-store.os-api.cci2.ecmwf.int/cci2-prod-catalogue/licences/licence-to-use-copernicus-products/licence-to-use-copernicus-products_b4b9451f54cffa16ecef5c912c9cebd6979925a956e3fa677976e0cf198c2c18.pdf)
for more information.
