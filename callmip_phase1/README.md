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

## What is NOT included: the meteorological forcing

The per-site **meteorological forcing** (e.g. `*_Met.nc`, which also carries LAI) is **not**
in the CalLMIP GitHub repository. Per the CalLMIP Phase 1 protocol (v2), the gap-filled
in-situ met forcing is downloaded from **modelevaluation.org (ME-org)**, the CalLMIP
workspace (requires an ME-org account). It derives from the **PLUMBER2 dataset**
(Abramowitz et al., 2024), which provides pre-selected **FLUXNET2015 (CC-BY-4.0)** sites.

Because ME-org requires authentication, the met forcing cannot be auto-downloaded here.
The forcing is CC-BY-4.0, so it may be redistributed (with citation): a companion artifact
that bundles the ME-org/PLUMBER2 met-forcing files (placed manually at build time) can be
created so a consuming package has both forcing and observations. See the consuming
package's docs for which path it expects.

## Source and citation

- Repository: https://github.com/callmip-org/Phase1 (MIT license)
- Project: CalLMIP — https://callmip-org.github.io
- The flux observations derive from FLUXNET2015; please also follow the FLUXNET2015 /
  ICOS data-use policy and cite the contributing sites.

When using this artifact, cite the CalLMIP project and the underlying FLUXNET2015 data.

## Recreating the artifact

```
cd callmip_phase1
julia --project create_artifact.jl
```

The script downloads the CalLMIP Phase 1 repository tarball, extracts its `Data/` tree,
and runs the guided artifact-creation flow. You will be asked to upload the produced
`callmip_phase1_artifact.tar.gz` to the Caltech Data Archive / Box and paste its direct
link; the resulting `OutputArtifacts.toml` entry is then copied into the consuming
package's `Artifacts.toml`. Pin `COMMIT` in `create_artifact.jl` to a specific CalLMIP
commit SHA for full reproducibility.
