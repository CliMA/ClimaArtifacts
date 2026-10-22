# Subset of datasets found on ILAMB

## Overview
This artifact containts the terrestrial water storage anomaly from GRACE at 0.5x0.5 degrees resolution. The data is downloaded from ILAMB [https://www.ilamb.org/ILAMB-Data/](https://www.ilamb.org/ILAMB-Data/). No preprocessing is done for this file.



## Usage
To recreate the artifact:
1. Navigate to this directory in the terminal.
1. Run `julia --project=. create_artifact_twsa.jl`


## References
GRACE land are available at http://grace.jpl.nasa.gov, supported by the NASA MEaSUREs Program.


F Landerer. 2021. TELLUS_GRAC_L3_CSR_RL06_LND_v04. Ver. RL06 v04. PO.DAAC, CA, USA. Dataset accessed [YYYY-MM-DD] at https://doi.org/10.5067/TELND-3AC64.

Landerer F.W. and S. C. Swenson, Accuracy of scaled GRACE terrestrial water storage estimates. Water Resources Research, Vol 48, W04531, 11 PP, doi:10.1029/2011WR011453, 2012.


Loomis et al., 2020, Geophys. Res. Lett., https://doi.org/10.1029/2019GL085488

Sun, Y., R. Riva, and P. Ditmar (2016), Optimizing estimates of annual variations and trends in geocenter motion and J2 from a combination of GRACE data and geophysical models, J. Geophys. Res. Solid Earth, 121, doi:10.1002/2016JB013073.

Wahr, J., M. Molenaar, and F. Bryan, Time-variability of the Earth's gravity field: Hydrological and oceanic effects and their possible detection using GRACE, J. Geophys. Res., 103, 32,20530,229, doi:10.1029/98JB02844, 1998.

## License
Creative Commons BY 4.0