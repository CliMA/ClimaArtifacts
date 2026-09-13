# All Sky Monthly averages of Solar-Induce Chlorphyll Fluoresence from 2018-2021

This artifact repackages data coming from TROPOMI ("https://ftp.sron.nl/open-access-data-2/TROPOMI/tropomi/sif/v2.1/l2b/")


Process:

Cycle through each day in a month and collect data from NetCDF file (if available)
	- Bin into 1\u00B0 by 1\u00B0 grid cell
Group data per month
	- Per day, apply spatial clipping function
		- Prevents outliers from affecting monthly mean
	- Per month, apply temporal clipping per 1\u00B0 by 1\u00B0 grid cell
		- Prevents extreme outliers in trends from affecting monthly mean
Calculate monthly average per grid cell per month
Calculate harmonic average error per grid cell per month 

The output is 4 NetCDF file that contains SIF values and errors binned into 1 degree x 1 degree bins per month

## Citations and Liscences:

NOVELTIS, UPV, SRON, LSCE, ESA (2021). The TROPOSIF global sun-induced fluorescence dataset 
from the TROPOMI mission: https://doi.org/10.5270/esa-s5p_innovation-sif-20180501_20210320
v2.1-202104 
Guanter, L., Bacour, C., Schneider, A., Aben, I., van Kempen, T. A., Maignan, F., Retscher, C., Köhler, 
P., Frankenberg, C., Joiner, J., Zhang, Y. (2021). The TROPOSIF global sun-induced fluorescence 
dataset from the Sentinel-5P TROPOMI mission, Earth Syst. Sci. Data ,https://doi.org/10.5194/essd
2021-199

The TROPOSIF products are made freely available to the scientific community, for non-commercial 
purposes only, under the Creative Common license BY-NC.

