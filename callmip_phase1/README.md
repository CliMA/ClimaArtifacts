# CalLMIP Phase 1 data

Evaluation data for **CalLMIP** (Calibration of Land Models Intercomparison Project)
**Phase 1**, packaged from the official repository
[`callmip-org/Phase1`](https://github.com/callmip-org/Phase1) (MIT license).

## Contents

The artifact mirrors the `Data/` tree of the CalLMIP Phase 1 repository:

| Path | Description |
|------|-------------|
| `Data/Phase1a-test/DK-Sor_daily_aggregated_1997-2013_FLUXNET2015_Flux.nc` | Flux observations for the **DK-Sor** (Sorø, Denmark) single-site **Phase 1a** test calibration: NEE, Qle, Qh and their uncertainties. Site metadata (PFT, % cover, soil-layer depths, soil texture) are in the global attributes. |
| `Data/Phase1b/*.nc` | Daily-aggregated flux observation files for the **21 Phase 1b sites** (same variable set). |
| `Data/Non-site-specific_forcing/CO2_1700_2024_TRENDYv2025.txt` | Atmospheric CO2 forcing (TRENDY v2025) for the site runs. |

## Meteorological forcing (companion artifact)

This artifact holds the flux **observations** and the **atmospheric CO₂ forcing** (listed
above). The per-site **meteorological forcing** (`*_Met.nc`, the atmospheric drivers + LAI) is
*not* part of the CalLMIP repository and is **not** included here — it is provided separately in
the companion [`callmip_phase1_forcing`](../callmip_phase1_forcing) artifact. Together the two
give a consuming package the observations + CO₂ forcing (here) and the meteorological drivers
(there).

## Source and citation

- Repository: https://github.com/callmip-org/Phase1 (MIT license)
- Project: **CalLMIP** (Calibration of Land Models Intercomparison Project),
  https://callmip-org.github.io
- Flux observations derive from **FLUXNET2015**: Pastorello, G., et al. (2020). The FLUXNET2015
  dataset and the ONEFlux processing pipeline for eddy covariance data. *Scientific Data* 7, 225.
  https://doi.org/10.1038/s41597-020-0534-3

When using this artifact, cite the **CalLMIP project** (https://callmip-org.github.io) and the
underlying **FLUXNET2015** data, and follow the FLUXNET2015 / ICOS data-use policy.

## Recreating the artifact

```bash
cd callmip_phase1
julia --project create_artifact.jl
```

The script downloads the pinned CalLMIP Phase 1 commit (`COMMIT` in `create_artifact.jl`,
which reproduces the `git-tree-sha1` in `OutputArtifacts.toml`), extracts its `Data/` tree, and
runs the guided artifact-creation flow. You will be asked to upload the produced
`callmip_phase1_artifact.tar.gz` and paste its direct link; the resulting `OutputArtifacts.toml`
entry is then copied into the consuming package's `Artifacts.toml`.
