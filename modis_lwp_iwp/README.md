Ice and Liquid Water Paths, from MODIS data for 2002-2025

This artifact repackages monthly average ice and liquid water path data coming from:
Borbas, E., et al., 2015. MODIS Atmosphere L2 Atmosphere Profile Product. NASA MODIS Adaptive Processing System, Goddard Space Flight Center, USA: http://dx.doi.org/10.5067/MODIS/MYD07_L2.061

To re-download the raw data, you need to [create](https://urs.earthdata.nasa.gov/users/new) an Earthdata account and generate an Earthdata Download Token.
Once you write your token to `~/.edl_token`, you can download the data with the following command:

```
wget -e robots=off -m -np -R .html,.tmp -nH --cut-dirs=3 --header "Authorization: Bearer $(cat ~/.edl_token)" "https://ladsweb.modaps.eosdis.nasa.gov/archive/allData/62/MCD06COSP_M3_MODIS/" -P .
```

The data is fetched in NetCDF format and combined into one file with the following variables:

- `lwp`: Liquid water path, kg m-2
- `iwp`: Ice water path, kg m-2
- `latitude`: Latitude, degrees north
- `longitude`: Longitude, degrees east
- `time`: Time since 2002-07-01T00:00:00, seconds

for each year from 2002-2025

License: Creative Commons Zero
