# Spun-up state of the optimal LAI model and CLM5 vegetation maps

This artifact holds three files used by ClimaLand:

| File | Grid | Content |
|---|---|---|
| `optimal_lai_state.nc` | 1° × 1° (360 × 180), 12 times | States of `ZhouOptimalLAIModel` on the first day of each month of 2008, NaN over ocean |
| `clm_tree_share.nc` | 0.9° × 1.25° (288 × 192) | `tree_share`: tree share of the natural vegetation in the CLM5 surface data, NaN where there is no natural vegetation |
| `clm_crop_fraction.nc` | 0.9° × 1.25° (288 × 192) | `crop_fraction`: fraction of the land in the crop land unit of the CLM5 surface data, NaN over ocean |

## `optimal_lai_state.nc`

The prognostic variables of the optimal LAI model of ClimaLand (Zhou et al., 2025),
`Y.canopy.biomass` of a `ZhouOptimalLAIModel`:

| Variable | Units | Description |
|---|---|---|
| `LAI` | m² m⁻² | Leaf area index |
| `A0_daily` | mol CO₂ m⁻² day⁻¹ | Daily potential GPP |
| `A0_annual` | mol CO₂ m⁻² yr⁻¹ | Annual potential GPP |
| `A0c3_annual`, `A0c4_annual` | mol CO₂ m⁻² yr⁻¹ | Annual potential GPP of a pure C3 and a pure C4 canopy |
| `GPPc3_annual` | mol CO₂ m⁻² yr⁻¹ | Annual C3 potential GPP scaled by fAPAR and the soil-moisture stress |
| `precip_annual` | mol H₂O m⁻² yr⁻¹ | Annual precipitation |
| `PET_annual` | mol H₂O m⁻² yr⁻¹ | Annual potential evapotranspiration |
| `VPDgs_annual` | Pa s yr⁻¹ | VPD summed while the air is above freezing |
| `growing_days` | days | Days above freezing in a year |
| `snow_store` | mol H₂O m⁻² | Degree-day snow store (no longer read by ClimaLand, which takes the melt from its snow model) |
| `water_30d`, `PET_30d` | mol H₂O m⁻² (30 days)⁻¹ | 30-day totals of the water input (rain and snowmelt) and of the PET |
| `VPD_moist_annual` | Pa s | VPD summed over the moist growing season |
| `moist_days` | days | Days of the moist growing season |
| `degree_days`, `warm_days` | K days, days | Degree-days and days above freezing |
| `maintenance_days` | days | Leaf maintenance load above freezing |
| `age` | s | Time since the start of the sums with a growing memory |

ClimaLand reads the state at the day of the year of the start date of a run,
interpolated between months. Where the file has data, its variables replace the
climatological seeds of the `optimal_lai_inputs` artifact.

The states were written by a spin-up of the global land model with prognostic LAI,
`experiments/long_runs/optimal_lai_spinup.jl` of ClimaLand.jl at commit `de43e9d7e` of PR
[#1901](https://github.com/CliMA/ClimaLand.jl/pull/1901), run on Buildkite (build 5127 of
`climaland-long-runs`). Forced by ERA5, it runs from March 1 2002, starting from the
`optimal_lai_inputs` climatology with a 1-year memory of the annual totals, until
December 1 2008. The state depends on the model and its parameters; it has to be
recreated when they change. The spin-up script, with `optimal_lai_spinup.toml` and
`optimal_lai_state.jl`, is kept on the
[`ar/lai_emulator`](https://github.com/CliMA/ClimaLand.jl/tree/ar/lai_emulator) branch of
ClimaLand.jl, not on its main branch; it takes about two and a half hours on a GPU and
writes `optimal_lai_spinup_gpu/optimal_lai_state.nc`.

In some months, the spin-up wrote 0 rather than NaN over part of the ocean: its land
mask came from a field whose ocean nodes were unset on the GPU. `create_artifact.jl`
sets every variable to NaN outside the cells that are finite in every month, which are
the active nodes of the model domain (22,420 cells); the land values are unchanged.

## `clm_tree_share.nc` and `clm_crop_fraction.nc`

Both maps come from the CLM5 surface data for the year 2000,
`surfdata_0.9x1.25_16pfts__CMIP6_simyr2000_c170616.nc`, from the
[CESM input data repository](https://svn-ccsm-inputdata.cgd.ucar.edu/trunk/inputdata/lnd/clm2/surfdata_map/)
(see also the `clm_data` artifact):

- the tree share is the percent cover of the tree PFTs (natpft 1-8) over that of all
  vegetated natural PFTs (natpft 1-14) in `PCT_NAT_PFT`;
- the crop fraction is `PCT_CROP / 100` where `LANDFRAC_PFT > 0`.

ClimaLand uses the tree share to weight the stem and root area indices between trees
and grasses, as an option for the tree share of the optimal LAI model, and as a target
of the vegetation leaderboard and of the calibration; it uses the crop fraction to
leave out cropland (more than 50% of the land) in them.

## Creating the artifact

```
julia --project create_artifact.jl
```

The script downloads the surface data (500 MB) and the spin-up state (kept by Buildkite
until April 2027), unless the environment variables `CLM_SURFDATA` and
`OPTIMAL_LAI_STATE` give local copies, and checks their SHA-256.

## References

- Zhou, S., et al. (2025). A general model for the seasonal to decadal dynamics of leaf
  area. *Global Change Biology*. https://doi.org/10.1111/gcb.70125
- Lawrence, D. M., et al. (2019). The Community Land Model Version 5: Description of new
  features, benchmarking, and impact of forcing uncertainty. *Journal of Advances in
  Modeling Earth Systems*, 11, 4245–4287. https://doi.org/10.1029/2018MS001583
