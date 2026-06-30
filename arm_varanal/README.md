# ARM SGP VARANAL

ARM SGP data for the VARANAL SCM case in ClimaAtmos.

| Artifact | Contents | Downloadable |
|----------|----------|--------------|
| `arm_sgp_varanal_forcing` | Sept 2010 VARANAL forcing (~2 MB) | Yes |
| `arm_sgp_varanal_obs` | 5-day obs subset (Sept 18–22, 2010, ~309 MB) | Yes |
| `arm_sgp_varanal_obs_full` | Full obs (Nov 2009 – Nov 2011, ~42 GB) | No |

The full obs exceeds the [500 MB downloadable limit](../README.md), so for CI
`create_artifact.jl` also produces `arm_sgp_varanal_obs`, a subset over the CI
window (`prognostic_edmfx_armvaranal_column`: start 20100918, t_end 4days).

## Artifact layout

All artifacts keep the original ARM product directory names. The raw data you
order from ARM is laid out by site:

```
arm_varanal_raw/
  sgp/                                    # Southern Great Plains, site C1
    sgp60varanarucC1.c1/                  #   VARANAL forcing
    sgpinterpolatedsondeC1.c1/            #   sonde (daily .nc files)
    sgparmbeatmC1.c1/                     #   best-estimate atm (yearly .cdf)
    sgparmbecldradC1.c1/                  #   cloud & radiation (yearly .cdf)
  <other_site>/                           #   future sites
```

The `obs_full` artifact is just this raw `sgp/` directory. On the cluster,
`Overrides.toml` makes the `obs_full` artifact resolve to this directory directly.

The downloadable `obs` artifact is a small subset with the same directory names
but only the files in the CI window:

```
arm_sgp_varanal_obs (artifact)
  sgpinterpolatedsondeC1.c1/              # 5 daily .nc files (Sept 18–22)
  sgparmbeatmC1.c1/                       # 1 time-subset .cdf
  sgparmbecldradC1.c1/                    # 1 time-subset .cdf
```

Adjust `SUBSET_START` / `SUBSET_END` in `create_artifact.jl` to match the CI window.

## Variables

Each product keeps its original ARM variable names. All variables are indexed by
`time`; vertical coordinates are `lev` (forcing), pressure `p` / height `z`
(best-estimate atm), and `height` (cloud/radiation and sonde). Most physical
variables come with a companion quality-control flag (`qc_*`) and, for the sonde,
a `source_*` flag. The main variables are:

- `sgp60varanarucC1.c1` (VARANAL forcing): `T`, `q`, `u`, `v`, `omega`, `div`,
  horizontal/vertical advective tendencies (`T_adv_h`, `T_adv_v`, `q_adv_h`,
  `q_adv_v`, `s_adv_h`, `s_adv_v`), dry static energy `s`, `dTdt`, `dqdt`,
  `dsdt`, apparent heating/moistening `q1`, `q2`, surface fields (`prec_srf`,
  `LH`, `SH`, `p_srf_aver`, `T_srf`, `RH_srf`, `wspd_srf`, `u_srf`, `v_srf`),
  radiation (`rad_net_srf`, `lw_net_toa`, `sw_net_toa`, `sw_dn_toa`), clouds
  (`cld_low`, `cld_mid`, `cld_high`, `cld_tot`, `cld_thick`, `cld_top`, `LWP`),
  column budgets, and `PW`.
- `sgparmbeatmC1.c1` (best-estimate atmosphere): profiles on pressure and height
  (`T_p`/`T_z`, `Td_p`/`Td_z`, `u_p`/`u_z`, `v_p`/`v_z`, `rh_p`/`rh_z`), surface
  fields (`u_sfc`, `v_sfc`, `T_sfc`, `rh_sfc`, `p_sfc`, `prec_sfc`), surface
  fluxes (`SH_baebbr`, `LH_baebbr`, `SH_qcecor`, `LH_qcecor`), and NWP fields
  (`*_nwp_p`).
- `sgparmbecldradC1.c1` (best-estimate cloud & radiation): cloud fraction
  (`cld_frac`, `cld_frac_MMCR`, `cld_frac_MPL`, `tot_cld`), shortwave/longwave
  radiation (`swdn`, `swup`, `swdif`, `swdir`, `lwdn`, `lwup`), `pwv`, `lwp`,
  TOA fluxes (`lw_net_TOA`, `sw_net_TOA`, `sw_dn_TOA`), and cloud layers
  (`cld_low`, `cld_mid`, `cld_high`, `cld_tot`, `cld_thick`, `cld_top`).
- `sgpinterpolatedsondeC1.c1` (interpolated sonde): height-resolved `temp`, `rh`,
  `rh_scaled`, `vap_pres`, `bar_pres`, `wspd`, `wdir`, `u_wind`, `v_wind`, `dp`
  (dewpoint), `potential_temp`, `sh` (specific humidity), and `precip`.

## Obtaining the raw data from ARM

ARM data cannot be downloaded with a direct link: the U.S. DOE ARM Data Center
requires a free user account and a manual data order, which can take some time to
process. To obtain this dataset:

1. Register for a free account at [ARM](https://www.arm.gov/) and log in to
   [ARM Data Discovery](https://adc.arm.gov/discovery/).
2. For site **Southern Great Plains (SGP), C1**, order these products:
   - `sgp60varanarucC1.c1` — VARANAL forcing (Sept 2010 for the forcing file)
   - `sgpinterpolatedsondeC1.c1` — interpolated sonde
   - `sgparmbeatmC1.c1` — best-estimate atmosphere
   - `sgparmbecldradC1.c1` — best-estimate cloud & radiation

   For the full obs artifact, order Nov 2009 – Nov 2011.
3. Download the order and place the product directories under a site folder so
   the layout matches the *Artifact layout* section above, e.g.
   `arm_varanal_raw/sgp/sgp60varanarucC1.c1/`, etc. By default the script looks
   for `arm_varanal_raw/sgp/` next to `create_artifact.jl`; set the
   `ARM_RAW_DATA_DIR` environment variable to point elsewhere.

## Reproduction

Once you have ordered the raw data and laid it out as described in *Obtaining the
raw data from ARM* above, run the following commands in a terminal to build the
artifacts:

```bash
cd arm_varanal
julia --project=. -e 'using Pkg; Pkg.develop(path="../ClimaArtifactsHelper.jl"); Pkg.instantiate()'

# point to your ARM order if it is not in ./arm_varanal_raw
export ARM_RAW_DATA_DIR=/path/to/arm_varanal_raw
julia --project=. create_artifact.jl
```

The script reads the raw data from `ARM_RAW_DATA_DIR/sgp/`. For the two
downloadable artifacts, it prompts you to upload tarballs to Caltech Box and paste
the static link. For the full obs artifact, it computes the hash from the raw site
directory and prints the `Overrides.toml` entry to add on the cluster.

### Postprocessing

The only postprocessing is restricting each obs product to the CI time window
(`SUBSET_START`–`SUBSET_END`): the yearly best-estimate files (`sgparmbeatmC1.c1`,
`sgparmbecldradC1.c1`) are subset along their `time` dimension, and the daily
interpolated-sonde files falling inside the window are copied as-is. The full obs
artifact is the raw data with no postprocessing.

## Citation and license

Atmospheric Radiation Measurement (ARM) user facility, Southern Great Plains (SGP)
C1 site, U.S. Department of Energy. Data are free of charge but use is governed by
the [ARM Data Policy](https://www.arm.gov/guidance/data-policies); please cite ARM
and the relevant data products (DOIs available via Data Discovery) in any
publications, per the policy.
