# RMSE for CMIP models

This artifacts contains the root mean square error (RMSE) in the seasonal climatology of precipitation, 
top-of-atmosphere (TOA) longwave (LW) radiation, and TOA shortwave (SW) radiation for different models in 
CMIP6 AMIP experiments. The data and script to calculate RMSE can be downloaded from the 
data repository [Will and Schneider 2024](https://data.caltech.edu/records/z24s9-nqc90).

Each HDF5 file contains the rmse of one variable. In each file there are two arrays, `rmse_amip_1yr` which
is the RMSE averaged over 1 simulated year and `rmse_amip` which is the RMSE averaged over 20 years. The
arrays are two dimensional, the first dimension is models and the second dimension is seasons. 

The models are:
```
'ACCESS-CM2','ACCESS-ESM1-5','BCC-CSM2-MR','BCC-ESM1','CAMS-CSM1-0','CIESM','CNRM-CM6-1','CNRM-CM6-1-HR',
'CNRM-ESM2-1','FGOALS-f3-L','GISS-E2-2-G','HadGEM3-GC31-LL','HadGEM3-GC31-MM','INM-CM4-8','INM-CM5-0','KACE-1-0-G'
'MIROC6','MIROC-ES2L','MPI-ESM1-2-HR','MRI-ESM2-0','NESM3','NorESM2-LM','SAM0-UNICON','UKESM1-0-LL'
```

And the seasons are: `DJF, MAM, JJA, SON, and annual mean`

License: Creative Commons Attribution 4.0 International
