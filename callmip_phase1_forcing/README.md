# CalLMIP Phase 1b meteorological forcing

Gap-filled in-situ **meteorological forcing** (atmospheric drivers + LAI) for the 21
**CalLMIP Phase 1b** calibration sites, as used by the CalLMIP Phase 1 experiments.

This is the **forcing/driver** companion to the [`callmip_phase1`](../callmip_phase1)
artifact, which provides the matching flux **observations** and CO2 forcing from the
CalLMIP GitHub repository.

## Contents

21 NetCDF files, one per site, named `<SITE>_<YEARS>_FLUXNET2015_Met.nc`, e.g.:

```
DK-Sor_1997-2014_FLUXNET2015_Met.nc   FI-Hyy_1996-2014_FLUXNET2015_Met.nc
CH-Dav_1997-2014_FLUXNET2015_Met.nc   DE-Hai_2000-2012_FLUXNET2015_Met.nc
... (21 sites total: CA-Qfo, CH-Dav, DE-Gri, DE-Hai, DE-Tha, DK-Sor, FI-Hyy,
FR-Pue, IT-Lav, IT-MBo, IT-Noe, NL-Loo, RU-Fyo, US-MMS, US-NR1, US-SRG, US-SRM,
US-Ton, US-Var, US-Whs, US-Wkg)
```

Each file carries the sub-daily meteorological drivers (and LAI) for the site.

## Source, provenance, license

Downloaded from the CalLMIP workspace on **modelevaluation.org (ME-org)** per the CalLMIP
Phase 1 protocol (v2). The data derive from the **PLUMBER2 dataset**
(Abramowitz et al., 2024, ESSD, https://doi.org/10.5194/essd-16-1389-2024), which provides
pre-selected **FLUXNET2015 (CC-BY-4.0)** sites. When using this artifact, cite PLUMBER2 and
FLUXNET2015 and follow the FLUXNET2015 data-use policy.

## Recreating the artifact

ME-org requires authentication, so the files cannot be auto-downloaded. Obtain the
Phase 1b met forcing from ME-org (the `Phase-1b-Calibration-DS.zip` download), then:

```
CALLMIP_MET_SRC=/path/to/Phase-1b-Calibration-DS.zip julia --project create_artifact.jl
```

(Alternatively point `CALLMIP_MET_SRC` at a directory containing the `*_Met.nc` files.)
The artifact is ~0.4 GB; `create_artifact_guided` will archive it and ask for the upload
link (Caltech Data Archive / Box) to produce the `OutputArtifacts.toml` entry. For
cluster-only use, instead upload the folder to
`/groups/esm/ClimaArtifacts/artifacts/callmip_phase1_forcing` and bind its hash via the
shared `Overrides.toml`.
