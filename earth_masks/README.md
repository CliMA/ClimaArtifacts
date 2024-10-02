# Earth Mask Datasets (Elevation, Land/Ocean)

This artifact regrids data from the [ETOPO2022](https://www.ncei.noaa.gov/products/etopo-global-relief-model) dataset, which contains ice-surface and bedrock orography / bathymetry information 
at three different resolutions: 15, 30, 60 arc-seconds. 

Input files are supplied as 288 NetCDF files (for the 15 arc-second product), 
each covering an approximate 15degx15deg panel.

Pre-processing of these input files involves regridding to a generated ClimaCore
horizontal spectral space at a given resolution, and storing the corresponding 
outputs as HDF5 files for use in ClimaAtmos. ClimaCore.InputOutput functions can
then directly be used to load mask / orography information in `ClimaLand`, `ClimaAtmos`
and `ClimaCoupler`. ClimaCore regridders can be used to generate coarse-grained data
for use in downstream Clima simulation tools.

The default download and pre-process steps use 15arc-second, ice-surface data.
For the default generated outputs: 

Inputs: 
- https://www.ngdc.noaa.gov/thredds/catalog/global/ETOPO2022/15s/15s_surface_elev_netcdf/catalog.html

Outputs: 
HDF5 format
- Land-sea mask (on 256 `h_elem` cubed-sphere)
- Binary ocean mask (on 256 `h_elem` cubed-sphere)
- Binary land mask (on 256 `h_elem` cubed-sphere)
- Ocean bathymetry (on 256 `h_elem` cubed-sphere)
- TODO: Binary sea-ice masks
- TODO: Binary inland lake masks
