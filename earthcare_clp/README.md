# EarthCARE ACM_CLP gridded monthly cloud fraction and water paths

Monthly cloud fraction on height levels and liquid and frozen water paths
from the JAXA EarthCARE ACM_CLP level 2b product (combined CPR radar, ATLID
lidar, and MSI imager cloud retrieval). Covers December 2025 to April
2026 on processing baseline JXBA, built from the granules already on
sampo. December starts on the 5th, the first day with granules there.

A granule is one product file: one orbit frame of about 5000 km of ground
track, a few thousand profiles with 206 height bins of 100 m. Every valid
bin is counted into a 2.5 deg by 2.5 deg by 500 m grid, and every profile's
water paths into the 2.5 deg column grid. Variable names and units follow
the `calipso_cloudsat` artifact so the same loader reads both.

## Variables

| Variable | Dims | Units | Definition |
|---|---|---|---|
| `cloud_fraction_on_levels` | lon, lat, height, time | % | cloudy bins / valid bins, times 100 |
| `cloud_counts_on_levels` | lon, lat, height, time | 1 | cloudy bins |
| `total_counts_on_levels` | lon, lat, height, time | 1 | valid bins |
| `lwp` | lon, lat, time | kg m^-2 | liquid water path, mean over all profiles |
| `fwp` | lon, lat, time | kg m^-2 | frozen water path, mean over all profiles |
| `profile_counts` | lon, lat, time | 1 | valid profiles |
| `baseline` | time | | processing baseline of the month |
| `n_granule` | time | 1 | granules in the month |

`height` is above mean sea level, 500 m bins from 0 to 20 km.

## Rules

Checked against JXBA and JXBB granules.

- A bin is valid when the cloud mask is 0 (clear) or 1 (cloud). Mask -9
  means not observed, below the surface or in surface clutter, and mask
  -127 is fill. Both are excluded from the counts.
- Water paths are per profile. A negative value (-9999) means no cloud and
  counts as zero, so the means are grid means. Values above 1e30 are fill
  and the profile is skipped. The liquid path includes rain and the frozen
  path includes snow, as retrieved.
- Units are converted from g m^-2 to kg m^-2 when the file says g.
- JXBA only by default. Set `BASELINE` empty in `earthcare_settings.jl`
  to process every baseline. The reader takes the first known variable
  name present in each file. A month with granules from two baselines is
  an error.
- Only granules starting from `START_DATE` up to but not including
  `END_DATE` are used.

## Settings

Directories, date range, and baseline are constants in
`earthcare_settings.jl`, included by both scripts. The MAAP token is read
from the `EARTHCARE_MAAP_TOKEN` environment variable. Get an offline token
at https://portal.maap.eo.esa.int/ini/services/auth/token/ .

## Usage

1. `julia --project=. -e 'using Pkg; Pkg.instantiate()'`
2. `GRANULE_DIR` points at the granules on sampo. To fetch them instead,
   set `GRANULE_DIR` to an empty directory and run
   `EARTHCARE_MAAP_TOKEN=<token> julia --project=. download.jl`. About
   3700 granules and 100 GB per month.
3. `julia --project=. create_artifact.jl`

Monthly files are written to `monthly/` under the output directory and
reused on rerun. The script asks for an upload link for each of the two
tarballs it makes.

## Files

There are two artifacts with the same variables.

- `earthcare_clp`: `earthcare_clp_2.5x2.5.nc`, 2.5 deg by 2.5 deg, 34 MB.
- `earthcare_clp_lowres`: `earthcare_clp_10x10.nc`, 10 deg by 10 deg,
  2 MB. Each cell sums the counts and water paths of 4 by 4 cells of the
  2.5 deg grid, the same grid as `calipso_cloudsat_lowres`. A 2.5 deg cell
  is crossed by the satellite only about 6 times a month, so the 10 deg
  grid is less noisy for single months.

## License

JAXA EarthCARE data policy. Open after registration.

## Citation

JAXA EORC, EarthCARE ACM_CLP Level 2 product, processing baseline JXBA.
https://www.eorc.jaxa.jp/EARTHCARE/data/L2/ACM_CLP_e.html
