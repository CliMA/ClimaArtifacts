# MODIS monthly cloud properties (MCD06COSP_M3)

Global monthly means from the MODIS MCD06COSP_M3 collection 062 product
(1 degree, 2002-07 to 2025), combined into a single NetCDF file
`modis_cloud_properties.nc` with dimensions `(time, latitude, longitude)`.

Variables:

| name | source group | units |
|---|---|---|
| `lwp` | Cloud_Water_Path_Liquid (Mean) | kg m-2 |
| `iwp` | Cloud_Water_Path_Ice (Mean) | kg m-2 |
| `reliq` | Cloud_Particle_Size_Liquid (Mean) | m |
| `reice` | Cloud_Particle_Size_Ice (Mean) | m |
| `clt` | Cloud_Mask_Fraction (Mean) | unitless (0-1 fraction) |

Notes:

- All fields are daytime retrievals (the source product masks by
  `Mask_Day`); the effective radii are cloud-top values from the
  3.7 micron retrieval over cloudy scenes.
- `clt` is the cloud-mask fraction, not the optical-properties retrieval
  fraction, so it counts all detected cloud regardless of whether an
  optical retrieval succeeded.
- Supersedes the `modis_lwp_iwp` artifact (same source dataset).

To recreate: run `julia --project=. create_artifact.jl` on a machine with
the raw MCD06COSP_M3_MODIS store (set `MODIS_DATA_DIR` if it is not at the
default Resnick path).

Citation: Borbas, E., et al., 2015. MODIS Atmosphere L2 Atmosphere Profile
Product. NASA MODIS Adaptive Processing System, Goddard Space Flight
Center, USA. http://dx.doi.org/10.5067/MODIS/MYD07_L2.061
