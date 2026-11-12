# Leaf area index of the land part of each cell, reprocessed MODIS Collection 6.1, 2000-2025

This recipe creates the `modis_lai_yuan_v061_0.25deg` artifact (169 MB). It holds the monthly
leaf area index (LAI) of the *land part* of each 0.25° grid cell, one file per year from 2000
to 2025, named `Yuan_et_al_YYYY_0.25x0.25.nc`.

It is the same product as the `modis_lai_0.25deg` artifact (recipe in the `modis_lai` folder
of CliMA/ClimaArtifacts#186). It uses the same aggregation over land, the same grid, the same
file names and the same variables and encoding. ClimaLand can switch between the two by
changing only the artifact name. The differences are:
- **Source:** the newer reprocessed MODIS Collection 6.1 release (version 6.1) from the data
  provider, instead of the earlier release served by GriddingMachine.jl.
- **Years:** 2000-2025 instead of 2000-2020.

The data comes from:
- Lin, W., Yuan, H., Dong, W., Zhang, S., Liu, S., Wei, N., Lu, X., Wei, Z., Hu, Y. and
  Dai, Y., 2023. Reprocessed MODIS Version 6.1 Leaf Area Index Dataset and Its Evaluation for
  Land Surface and Climate Modeling. Remote Sensing, 15(7), 1780.
  https://doi.org/10.3390/rs15071780
- Hua Yuan, Yongjiu Dai, Zhiqiang Xiao, Duoying Ji, Wei Shangguan, Reprocessing the MODIS
  Leaf Area Index products for land surface and climate modelling, Remote Sensing of
  Environment, Volume 115, Issue 5, 2011, Pages 1171-1187,
  https://doi.org/10.1016/j.rse.2011.01.001

It is downloaded at 0.05° (monthly, NetCDF) from the Land-Atmosphere Interaction Research
Group at Sun Yat-sen University,
`http://globalchange.bnu.edu.cn/laiv061/global_lai_0.05/lai_monthly_0.05_YYYY.nc`
(project page: http://globalchange.bnu.edu.cn/research/laiv061). The 2025 file used here was
created by the provider on 2026-11-01.

Each file contains:
  - `lai` (lon, lat, time): leaf area index of the land part of the cell, m² m⁻².
    It is stored as `Int16` with `scale_factor = 0.001`; NetCDF readers that
    follow the CF conventions (NCDatasets.jl, ClimaUtilities, ClimaAnalysis,
    xarray) unpack it to floats.
  - `land_fraction` (lon, lat): land fraction of the cell (ETOPO 2022 with
    lakes removed and land below sea level added). It is identical to the one in
    `modis_lai_0.25deg`.
  - `lat`, `lon`: cell centers, degrees north and east
  - `time`: 12 values, 30 days apart starting on January 1 (even spacing is
    required by ClimaLand's `PeriodicCalendar`)

To recreate the artifact, run `julia --project create_artifacts.jl` in this folder.
- It downloads 5.1 GB of 0.05° data to `yuan_v061_source/`, which is removed at the end.
- To reuse files you have already downloaded, set `YUAN_V061_DIR` to their folder; they are
  then kept.
- Aggregation takes about 5 minutes and needs about 10 GB of memory.

## Aggregation over land

This is the same as for `modis_lai_0.25deg`; see the README of the `modis_lai` folder in
CliMA/ClimaArtifacts#186 for the details and the justification.
`land_fraction_correction.jl` is a copy of the file of that PR; only its header comment
changed. In short, the LAI of each output cell is

    LAI = Σ a LAI_pixel / Σ a f

over its 0.05° pixels, where:
- `a` is the area of the pixel;
- `LAI_pixel` is the LAI of the pixel (0 where the source has no vegetation or water);
- `f` is the land fraction of the pixel. It comes from the ETOPO 30″ land-sea mask, with lakes
  removed using the ERA5 land fraction, land below sea level added back, and at least 0.5 for
  pixels that are vegetated in some month.

The source stores water and bare ground as LAI = 0, which the recipe reads as missing, as the
GriddingMachine files do. Ocean cells are filled from the nearest cells.

The "vegetated in some month" mask uses all years processed (2000-2025 here). Building
2000-2020 only gives bit-identical files for those years, so adding years does not change the
land fractions.

## Comparison with `modis_lai_0.25deg` (2000-2020)

Same recipe, different source release. Per year, comparing the two artifacts over land:
- the spatial correlation is 0.9993-0.9999;
- 89-95% of cell-months differ by at most 0.05 m² m⁻²;
- about 42% are identical.

The land-area-weighted global mean LAI of this artifact is higher than that of
`modis_lai_0.25deg` by:

| years   | 2000-2002 | 2003-2004 | 2010 | 2015 | 2020 |
| ------- | --------- | --------- | ---- | ---- | ---- |
| ratio   | 1.012-1.014 | 1.018-1.019 | 1.017 | 1.012 | 1.003 |

So the two releases differ by about 1.5% of LAI in their 2003-2020 trend. North of 50°N the
annual-mean ratio goes from 1.027 (2003) to 0.984 (2020).

## Limitations

- The limitations of `modis_lai_0.25deg` apply:
  - small lakes dilute the LAI;
  - land below sea level is only partly recovered;
  - mostly-water cells take the LAI of their shoreline.
- **2023-2025: MODIS-based LAI may be biased low.**
  - **Orbit drift:** the Terra and Aqua orbits have drifted since 2020-2022, so MODIS now sees
    the surface at larger solar zenith angles: Terra earlier in the morning, Aqua later in the
    afternoon.
  - **Evidence at 29 NEON towers:** on the same site-months, the original MODIS C6.1 LAI
    (MOD15A2H and MYD15A2H, 3 × 3 pixels of 500 m) falls relative to VIIRS (VNP15A2H v002):
    by 2.5% in 2023, 8% in 2024 and 12% in 2025, against the 2016-2022 ratio.
  - **This product:** it shows about half of that decline: −1.6%, −4.6% and −7.3%.
  - **VIIRS** shows no decline; its 2025 LAI is 1.9% above its 2016-2024 mean.
  - **Status:** this is an unpublished check at US sites only. Check it before using the
    2023-2025 trends.
- **The last year is provisional:** the 2025 file is new, and the provider may reprocess the
  last years when it adds new ones.

License: see the terms of the data provider (project page above); cite Lin et al. (2023) and
Yuan et al. (2011) when using this artifact.
