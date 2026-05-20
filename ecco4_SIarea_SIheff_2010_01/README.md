# ECCO v4 Sea-ice Concentration and Thickness (January 2010)

This artifact contains ECCO v4 data for average sea-ice concentration and sea-ice thickness for the month of January, 2010.
The data is interpolated onto a regular lat-lon grid with 1/4° resolution.
See https://ecco-group.org/products-ECCO-V4r4.htm for more details.

The artifact is set as undownloadable because ECCO requires authentication.
Before running `create_artifacts.jl`, you must first register for an Earthdata account at https://urs.earthdata.nasa.gov/users/new.
Then use your login information to create a `.env` file with the following content:
```
ECCO_USERNAME=your_ecco_username
ECCO_WEBDAV_PASSWORD=your_ecco_webdav_password
```

After running `create_artifacts.jl`, the subfolder `ecco4_SIarea_SIheff_2010_01_artifact` should contain the following files:
- `SIarea_2010_01.nc` (2.1 MB)
- `SIheff_2010_01.nc` (2.1 MB)

## Citation

*ECCO Consortium, Fukumori, I., Wang, O., Fenty, I., Forget, G., Heimbach, P., & Ponte, R. M. (May 14, 2026). ECCO Central Estimate (Version 4 Release 4). Retrieved from https://ecco.jpl.nasa.gov/drive/files/Version4/Release4/interp_monthly/SIarea/2010/SIarea_2010_01.nc and https://ecco.jpl.nasa.gov/drive/files/Version4/Release4/interp_monthly/SIheff/2010/SIheff_2010_01.nc.