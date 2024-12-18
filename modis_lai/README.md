# Leaf Area Index, derived from MODIS data for 2008

This artifact repackages data coming from:
Hua Yuan, Yongjiu Dai, Zhiqiang Xiao, Duoying Ji, Wei Shangguan,Reprocessing the MODIS Leaf Area Index products for land surface and climate modelling, Remote Sensing of Environment, Volume 115, Issue 5, 2011, Pages 1171-1187, ISSN 0034-4257, https://doi.org/10.1016/j.rse.2011.01.001.

The data is fetched in NetCDF format and reprojected to WGS84 via the GriddingMachine.jl package:
Y. Wang, P. Köhler, R. K. Braghiere, M. Longo, R. Doughty, A. A. Bloom, and C. Frankenberg. 2022. GriddingMachine, a database and software for Earth system modeling at global and regional scales. Scientific Data. 9: 258. [DOI](https://doi.org/10.1038/s41597-022-01346-x)

We regrid the data to 1 degree resolution, and output a netCDF file with the following variables:
  - `lai`  : Leaf area index, m^2/m^2
  - `lat`  : Latitude, degrees north
  - `lon`  : Longitude, degrees east
  - `month`: Month of the year, in `DateTime` format

License: Creative Commons Zero
