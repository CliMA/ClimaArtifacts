# CalLMIP Phase 1b meteorological forcing

Gap-filled in-situ **meteorological forcing** (atmospheric drivers + LAI) for the 21
**CalLMIP Phase 1b** calibration sites, as used by the CalLMIP Phase 1 experiments.

This is the **forcing/driver** companion to the [`callmip_phase1`](../callmip_phase1)
artifact, which provides the matching flux **observations** and CO2 forcing from the
CalLMIP GitHub repository.

## Contents

21 NetCDF files, one per site, named `<SITE>_<YEARS>_FLUXNET2015_Met.nc`. Each file carries the
sub-daily meteorological drivers (and LAI) for one site.

**The year coverage differs by site** — it is encoded in each filename. For example:

```
DK-Sor_1997-2014_FLUXNET2015_Met.nc   (1997–2014)
FI-Hyy_1996-2014_FLUXNET2015_Met.nc   (1996–2014)
DE-Hai_2000-2012_FLUXNET2015_Met.nc   (2000–2012)
```

The 21 sites are: CA-Qfo, CH-Dav, DE-Gri, DE-Hai, DE-Tha, DK-Sor, FI-Hyy, FR-Pue, IT-Lav,
IT-MBo, IT-Noe, NL-Loo, RU-Fyo, US-MMS, US-NR1, US-SRG, US-SRM, US-Ton, US-Var, US-Whs, US-Wkg.

## Source, provenance, license

Downloaded from the CalLMIP workspace on **modelevaluation.org (ME-org)**,
https://modelevaluation.org/, per the CalLMIP Phase 1 protocol (v2). The data derive from the
**PLUMBER2 dataset** (Abramowitz et al., 2024, ESSD, https://doi.org/10.5194/essd-16-1389-2024),
which provides pre-selected **FLUXNET2015 (CC-BY-4.0)** sites: Pastorello, G., et al. (2020). The
FLUXNET2015 dataset and the ONEFlux processing pipeline for eddy covariance data. *Scientific
Data* 7, 225. https://doi.org/10.1038/s41597-020-0534-3

When using this artifact, cite **PLUMBER2** and **FLUXNET2015** and follow the FLUXNET2015
data-use policy.

## Recreating the artifact

ME-org (https://modelevaluation.org/) requires authentication, so the files cannot be
auto-downloaded. Obtain the Phase 1b met forcing from the CalLMIP workspace on ME-org (the
`Phase-1b-Calibration-DS.zip` download), then:

```bash
CALLMIP_MET_SRC=/path/to/Phase-1b-Calibration-DS.zip julia --project create_artifact.jl
```

(Alternatively point `CALLMIP_MET_SRC` at a directory containing the `*_Met.nc` files.)
The artifact is ~0.4 GB; `create_artifact_guided` will archive it and ask for the upload link to
produce the `OutputArtifacts.toml` entry.
