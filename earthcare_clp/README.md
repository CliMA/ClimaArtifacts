# EarthCARE ACM_CLP gridded monthly cloud statistics

Monthly gridded cloud fraction, cloud liquid and ice water content,
supercooled liquid fraction (SLF), and SLF versus temperature from the JAXA
EarthCARE ACM_CLP level 2 product (combined CPR radar, ATLID lidar, and MSI
imager cloud retrieval). The catalogue holds granules from mid 2024 onward.

A granule is one product file: one orbit frame of about 5000 km of ground
track, a few thousand profiles with 200 height bins each. Every valid range
bin of every granule is binned into two grids.

## Grid A: `(lon, lat, z, pass, time)`

2.5 deg by 2.5 deg by 500 m from 0 to 20 km above mean sea level. `pass` is
1 for ascending (about 02:00 local) and 2 for descending (about 14:00 local).

| Variable | Units | Definition |
|---|---|---|
| `cloud_fraction_on_levels` | 1 | cloudy bins / valid bins |
| `cloud_liquid_water_content` | kg m^-3 | grid mean, zeros included |
| `cloud_ice_water_content` | kg m^-3 | grid mean, zeros included |
| `supercooled_liquid_fraction` | 1 | sum(liquid) / sum(liquid + ice) |
| `temperature` | K | grid mean of the ECMWF auxiliary temperature |
| `cloud_liquid_variance`, `cloud_ice_variance` | kg^2 m^-6 | within-box variance |
| `n_total`, `n_cloud`, `n_clutter` | 1 | bin counts |
| `n_overpass` | 1 | granules contributing, `(lon, lat, pass, time)` |

## Grid B: `(lat_band, tbin, pass, time)`

10 deg latitude bands by 2 K temperature bins from 235.15 to 273.15 K,
ocean only.

| Variable | Units | Definition |
|---|---|---|
| `slf_by_temperature` | 1 | sum(liquid) / sum(liquid + ice) per bin |
| `cloud_fraction_by_temperature` | 1 | cloudy bins / valid bins per bin |
| `n_total_by_temperature`, `n_cloud_by_temperature` | 1 | bin counts |

## Rules

- Liquid is cloud liquid only. Rain is not added.
- Bins with any value at or below -9000 are fill and are not counted.
- Surface clutter bins are counted in `n_clutter` and nowhere else.
- One processing baseline per month. The baseline and the water content
  variable names it uses are global attributes.

## Settings

All settings are environment variables, documented at the top of each script.

| Variable | Used by | Default |
|---|---|---|
| `EARTHCARE_MAAP_TOKEN` | `download.jl` | none, required |
| `EARTHCARE_CLP_DIR` | both | `granules/` in this folder |
| `EARTHCARE_START` | `download.jl` | `2024-06-01T00:00:00`, mission start |
| `EARTHCARE_END` | `download.jl` | now |
| `EARTHCARE_OUTPUT_DIR` | `create_artifact.jl` | this folder |

The token is an offline token from
https://portal.maap.eo.esa.int/ini/services/auth/token/ . The dates select
granules by start time.

## Usage

1. `julia --project=. -e 'using Pkg; Pkg.develop(path="../ClimaArtifactsHelper.jl"); Pkg.instantiate()'`
2. `julia --project=. download.jl`, or point `EARTHCARE_CLP_DIR` at a
   directory that already holds the granules. About 3400 granules per month.
3. `julia --project=. create_artifact.jl`

Monthly files are written to `monthly/` under the output directory and
reused on rerun. The stitched file is
`earthcare_clp_artifact/earthcare_clp_2.5x2.5.nc`, a few hundred MB.

Test the download on one orbit:

```
export EARTHCARE_MAAP_TOKEN=<token>
export EARTHCARE_CLP_DIR=/tmp/earthcare_test
export EARTHCARE_START=2026-01-05T00:00:00
export EARTHCARE_END=2026-01-05T02:00:00
julia --project=. download.jl
```

Expect about 8 granules. A second run skips them all.

## Before the first run

The `CLUTTER` and `OCEAN` flag values in `create_artifact.jl` must be checked
against the flag tables in the ACM_CLP vBb release note.

## License

JAXA EarthCARE data policy. Open after registration.

## Citation

JAXA EORC, EarthCARE ACM_CLP Level 2 product, baseline vBb.
https://www.eorc.jaxa.jp/EARTHCARE/data/L2/ACM_CLP_e.html
