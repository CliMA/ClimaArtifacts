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
