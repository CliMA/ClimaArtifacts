# Ozone data, monthly means, from 1950 to 2014

This artifact repackages data coming from [CMIP6 forcing datasets](https://www.wdc-climate.de/ui/cmip6?input=input4MIPs.CMIP6.CMIP.UReading.UReading-CCMI-1-0) and
contains volume mixing ratio of ozone.

The input file is defined in pressure coordinates. We convert this into altitude over mean-sea level
using $P = P^*exp(-z / H)$ with scale height $H$. We assume $P^* = 1e5$ (Pa) and $H = 7000$ (m). The output 
is a NetCDF file that contains volume mixing ratio (in mol/mol) of ozone defined on a lon-lat-z-time grid.

The script also produces a `lowres` version. The `lowres` version contains two
years of data only (the first and the last of the input), it is at 1/6th of the
resolution, and single-point precision.


License: Creative Commons Attribution-ShareAlike 4.0 International
