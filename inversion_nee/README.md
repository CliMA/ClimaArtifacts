# Derived NEE, GPP, ER, and Rh for terrestrial-model calibration

## Overview

This artifact provides four derived global flux fields on a 1°×1° monthly grid
(2002–2020), intended for calibration of terrestrial biosphere models such as
ClimaLand:

| Field | Definition | Sign convention |
|---|---|---|
| **NEE** | Net Ecosystem Exchange | positive = source to atmosphere |
| **GPP** | Gross Primary Production | positive = uptake by ecosystem |
| **ER**  | Ecosystem Respiration | positive = source to atmosphere |
| **Rh**  | Heterotrophic Respiration | positive = source to atmosphere |

The four fields are derived from four open data products:

```
NEE  =  CarbonTracker CT2022 bio_flux_opt              (positive = source)
GPP  =  GOSIF-GPP, regridded                           (positive = uptake)
ER   =  NEE  +  GPP                                    (positive = source)
Rh   =  Hashimoto Rs_monthly × (Rh_annual / Rs_annual) (positive = source)
```

- **NEE**: NOAA CarbonTracker CT2022 monthly 1°×1° optimized biospheric flux
  (`bio_flux_opt`). CT2022 is an atmospheric-inversion product that
  prescribes fossil fuel and fire (GFED4.1s) emissions and solves for the
  biospheric + ocean components against atmospheric CO₂ observations.
  `bio_flux_opt` is therefore an NEE-like quantity with **fire already
  separated out** (see `fire_ct` diagnostic in the output). Residual
  contamination is land-use change and lateral fluxes (rivers, wood/crop
  trade).
- **GPP**: GOSIF-GPP v2 (Li & Xiao 2019), a machine-learning-based GPP
  product driven by satellite-observed solar-induced fluorescence (SIF) and
  meteorology, regridded from 0.05° to 1°.
- **ER**: ecosystem respiration derived as the residual `ER = NEE + GPP`.
  Suitable for use with a calibration cost function that puts looser noise
  on GPP and ER and tighter noise on NEE (since NEE is the most direct
  observational constraint and ER inherits the uncertainties of both
  inputs).
- **Rh**: heterotrophic respiration, derived from Hashimoto 2015 by scaling
  monthly Rs (the only Hashimoto monthly product) by the per-pixel annual
  Rh/Rs ratio:
  ```
  ratio[lon,lat,y]    = Rh_annual[lon,lat,y]
                        / sum_m (Rs_monthly[lon,lat,y,m] * days_in_month(y,m))
  Rh_monthly[m, day⁻¹]= Rs_monthly[m, day⁻¹] * ratio[y]
  ```
  This preserves the annual Hashimoto Rh by construction and inherits Rh
  seasonality from Rs (assumes Rh/Rs constant within a year per pixel).
  Hashimoto coverage ends in 2012; 2013–2020 are filled with the
  2002–2012 monthly climatology (per pixel, per calendar month). Intended
  as a *soft constraint* in calibration (a magnitude prior on Rh) rather
  than a pixel-by-pixel target.

To compare with ClimaLand outputs that use the ecologist convention
(NEE positive = uptake), flip the sign of `nee`, `er`, and `rh`.

> ⚠️ **Unit inconsistency by design**: `rh` is stored in **g C m⁻² day⁻¹**
> (Hashimoto native units), while `nee`, `gpp`, `er` are in **g C m⁻² month⁻¹**.
> This avoids a day⁻¹ → month⁻¹ → day⁻¹ round-trip in the ClimaLand
> calibration loader, which would introduce a ±5% spurious seasonality
> (because the loader uses a constant 365.25/12 days per month, but real
> months are 28–31 days). Check the `units` attribute on each variable.

## Data sources and choices

| Source | Product | Spatial res. | Temporal res. | URL |
|---|---|---|---|---|
| CarbonTracker CT2022 | Monthly 1°×1° fluxes | 1°×1° | monthly | https://gml.noaa.gov/aftp/products/carbontracker/co2/CT2022/fluxes/monthly/ |
| GFED5.1 | Global Fire Emissions Database v5 | 0.25°×0.25° | monthly | https://zenodo.org/records/16794692 |
| GOSIF-GPP v2 | SIF-based GPP, monthly Mean GeoTIFFs | 0.05°×0.05° | monthly | http://data.globalecology.unh.edu/data/GOSIF-GPP_v2/Monthly/Mean/ |
| Hashimoto 2015 | Global gridded Rs (monthly) and Rh (annual) | 0.5°×0.5° | monthly Rs, annual Rh | https://zenodo.org/records/4708444 |

### Why these choices
- **CarbonTracker CT2022 over OCO-2 v10 MIP.** Initial plan was to use the
  CEOS open ensemble file from the OCO-2 v10 MIP (Byrne et al. 2022). On
  inspection, the CEOS file ships **annual** fluxes only (2015–2020, one
  timestep per year). For monthly calibration we needed a different source.
  CT2022 provides monthly 1°×1° fluxes, is freely downloadable from NOAA
  without registration, and uses similar atmospheric-inversion machinery.
  Trade-off: CT2022 is a single inversion (no ensemble spread), so the
  calibration must define NEE noise from external estimates (literature,
  CT-vintage-spread, regional standard deviations).
- **`bio_flux_opt` directly as NEE.** CT2022 separates fire from the
  biospheric flux internally (CT prescribes fire from GFED4.1s). So
  `bio_flux_opt` is already fire-excluded and can be used directly as the
  NEE-like quantity. GFED5 is included only as a diagnostic.
- **2002–2020.** Widest range supported by the intersection of the three
  inputs. The start year (2002) is set by GFED5.1, which begins in 2002.
  The end year (2020) is set by CT2022, which ends at 202102 — so 2020 is
  the last complete year. CT2022 itself begins in 2000 and GOSIF-GPP v2 in
  2000.03, but neither extends what GFED5/CT2022 allow. Adjust
  `YEAR_START` / `YEAR_END` in the script if you need a narrower window;
  going wider requires swapping one of the three inputs.
- **GFED5, kept as diagnostic.** GFED5 supersedes GFED4.1s with improved
  burned-area inputs. We retain it in the output for users who want to
  cross-check or re-derive NEE with a different fire-handling assumption.
- **No LUC subtraction.** BLUE and other bookkeeping models do not publish a
  clean gridded annual non-fire-only LUC product. The residual LUC emissions
  remain in the "NEE" product. This biases the derived NEE toward a stronger
  source in tropical deforestation hotspots (Amazonia, Indonesia, central
  Africa, ~0.5–1 PgC/yr globally). Calibration should either mask these
  regions or model the bias explicitly. **This LUC bias also propagates into
  ER** by construction (`ER = NEE + GPP`).
- **GOSIF-GPP, not FluxSat or BESS.** GOSIF-GPP (Li & Xiao 2019) is widely
  used, has long coverage (2000–2023), and matches FLUXNET tower GPP well
  globally. Alternatives (FluxSat, BESS, FluxCom) would change the GPP
  spatial pattern modestly; consider an ensemble of GPP products in future
  iterations.

## Limitations and known biases

1. **Land-use change emissions** (~1 PgC/yr globally) are not subtracted. The
   derived field is NEE + LUC + small residual lateral fluxes.
2. **River lateral C transport** (~0.6–0.8 PgC/yr globally; Regnier et al. 2022)
   is included in the inversion's land term and not removed. This is a
   systematic land source that biology did not emit.
3. **Ensemble mean masks structural disagreement.** The ensemble spread is
   provided alongside the mean; use it as the observational uncertainty in any
   calibration. Regional spread is large (especially tropics, high latitudes).
4. **Prior contamination.** Most inversions use bottom-up LSM priors. In
   data-poor regions the posterior leans on the prior, partially calibrating
   against another model. Use FLUXNET or other independent data to validate.
5. **Time window** restricted to 2002–2020 by the intersection of the three
   source products (GFED5.1 starts in 2002; CT2022 ends in Feb 2021).
   Extending past 2020 requires moving to a newer CarbonTracker vintage
   (e.g., CT2025 or an open OCO-2 v11 ensemble).
6. **GPP and ER share NEE biases.** Because ER is computed as `NEE + GPP`,
   any LUC/lateral-flux bias in NEE shows up identically in ER. Tightening
   the noise on NEE while loosening it on GPP/ER (the planned EKP setup) is
   consistent with this: NEE is the more direct constraint; GPP and ER are
   each informed by one independent observation stream (SIF for GPP, the
   residual for ER) plus the NEE constraint.
7. **GOSIF-GPP retrieval uncertainty** (~10–20%) is not propagated here.
   GOSIF v2 ships a separate "SD" GeoTIFF series at
   http://data.globalecology.unh.edu/data/GOSIF-GPP_v2/Monthly/SD/ — a
   future revision could ingest these and propagate through to ER.

## Output file

`derived_nee_gpp_er_rh_2002_2020.nc` contains:

| Variable | Units | Sign | Description |
|---|---|---|---|
| `nee` | g C m⁻² month⁻¹ | + = source | NEE = CT2022 `bio_flux_opt` (fire already separated) |
| `gpp` | g C m⁻² month⁻¹ | + = uptake | GOSIF-GPP, regridded to 1°×1° |
| `er` | g C m⁻² month⁻¹ | + = source | Ecosystem Respiration = NEE + GPP |
| `rh` | **g C m⁻² day⁻¹** | + = source | Heterotrophic respiration, Hashimoto Rs × annual Rh/Rs; 2013–2020 climatology-filled |
| `fire_gfed5` | g C m⁻² month⁻¹ | + = source | GFED5.1 C emissions, regridded (diagnostic) |
| `fire_ct` | g C m⁻² month⁻¹ | + = source | CT2022 imposed fire (GFED4.1s, diagnostic) |
| `time` | days since 2002-01-15 | — | Mid-month timestamps |
| `lat`, `lon` | degrees | — | 1°×1° pixel centers |

Note: `rh` uses **day⁻¹** units while nee/gpp/er use **month⁻¹** — see Overview.

## Prerequisites

- Julia ≥ 1.10
- Internet connection (~3.9 GB of downloads: ~450 MB CT2022 + ~290 MB GFED5 +
  ~1.6 GB GOSIF-GPP + ~1.5 GB Hashimoto Rs+Rh, compressed)
- ~5 GB free disk space for intermediate files (decompressed GOSIF TIFFs
  expand to ~3.6 GB)

## Usage

To recreate the artifact:

1. Clone this repository and navigate to this directory.
2. Run `julia --project=. -e 'using Pkg; Pkg.instantiate()'` once.
3. Run `julia --project=. create_artifact.jl`.

The script is idempotent — it will skip downloads of files that already exist.

## References

**OCO-2 v10 MIP ensemble**
- Byrne, B., Baker, D.F., Basu, S., et al. (2022): Pilot top-down CO₂ Budget
  constrained by the v10 OCO-2 MIP, Version 1. Committee on Earth Observing
  Satellites. https://doi.org/10.48588/npf6-sw92
- Byrne, B., et al. (2023): National CO₂ budgets (2015–2020) inferred from
  atmospheric CO₂ observations in support of the global stocktake. *Earth
  System Science Data*, 15, 963–1004. https://doi.org/10.5194/essd-15-963-2023

**GFED5**
- Chen, Y., Hall, J., van Wees, D., et al. (2023): Multi-decadal trends and
  variability in burned area from the fifth version of the Global Fire
  Emissions Database (GFED5). *Earth System Science Data*, 15, 5227–5259.
  https://doi.org/10.5194/essd-15-5227-2023
- Data: https://zenodo.org/records/16794692

**GOSIF-GPP**
- Li, X. & Xiao, J. (2019): A Global, 0.05-Degree Product of Solar-Induced
  Chlorophyll Fluorescence Derived from OCO-2, MODIS, and Reanalysis Data.
  *Remote Sensing*, 11(5), 517. https://doi.org/10.3390/rs11050517
- Data: http://data.globalecology.unh.edu/data/GOSIF-GPP_v2/

**Hashimoto Rs/Rh**
- Hashimoto, S., Carvalhais, N., Ito, A., Migliavacca, M., Nishina, K. &
  Reichstein, M. (2015): Global spatiotemporal distribution of soil
  respiration modeled using a global database. *Biogeosciences*, 12,
  4121–4132. https://doi.org/10.5194/bg-12-4121-2015
- Data: https://zenodo.org/records/4708444

**Methodological background**
- Friedlingstein, P., et al. (2024): Global Carbon Budget 2024. *Earth System
  Science Data*. https://doi.org/10.5194/essd-2024-519
- Regnier, P., et al. (2022): The land-to-ocean loops of the global carbon
  cycle. *Nature*, 603, 401–410. https://doi.org/10.1038/s41586-021-04339-9

## License

- OCO-2 v10 MIP CEOS file: open access. Cite Byrne et al. 2022 (DOI above).
- GFED5: CC-BY 4.0. Cite Chen et al. 2023.
- GOSIF-GPP v2: free for non-commercial scientific research; cite Li & Xiao
  2019.
- Hashimoto 2015 Rs/Rh dataset: cite Hashimoto et al. 2015.

This derived product inherits the most restrictive license of its inputs.
Please cite all four source papers and this artifact when using.
