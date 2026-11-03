# Foliage clumping index, derived from MODIS data for 2006

This artifact repackages data coming from:
He, L., J.M. Chen, J. Pisek, C. Schaaf, and A.H. Strahler. 2017.  Global 500-m Foliage Clumping Index Data Derived from MODIS BRDF, 2006. ORNL DAAC, Oak Ridge, Tennessee, USA. [DOI](https://doi.org/10.3334/ORNLDAAC/1531)

The data is fetched in NetCDF format and reprojected to WGS84 via the GriddingMachine.jl package:
Y. Wang, P. Köhler, R. K. Braghiere, M. Longo, R. Doughty, A. A. Bloom, and C. Frankenberg. 2022. GriddingMachine, a database and software for Earth system modeling at global and regional scales. Scientific Data. 9: 258. [DOI](https://doi.org/10.1038/s41597-022-01346-x)

We regrid the data to 1 degree resolution, and output a netCDF file with the following variables:
  - `ci`: Foliage clumping index, unitless
  - `lat`: Latitude, degrees north
  - `lon`: Longitude, degrees east

License: Creative Commons Zero

## Reproducing the artifact

Run `julia +1.11 --project create_artifacts.jl` with the committed `Manifest.toml`.
It pins GriddingMachine 0.2.9 (0.4.0 fails to load) and the `NetCDF_jll` and
`HDF5_jll` builds, whose versions are written into the output file, so other builds
change the artifact's `git-tree-sha1` even when the data is identical. The pinned
`NetCDF_jll` requires Julia 1.11 or older. GriddingMachine stores its downloads in
`~/GriddingMachine`.
