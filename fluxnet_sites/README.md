# Selected FLUXNET tower site data

FLUXNET flux tower site data is used to validate ClimaLand on a site-level basis. The data must be manually downloaded from the FLUXNET website before running this script. We don't perform any preprocessing on this data before using it in our simulations. Source:
Pastorello, G., Trotta, C., Canfora, E. et al. The FLUXNET2015 dataset and the ONEFlux processing pipeline for eddy covariance data. Sci Data 7, 225 (2020). https://doi.org/10.1038/s41597-020-0534-3

To download the data, visit the fluxnet data download page here: https://ameriflux.lbl.gov/data/download-data/. To download, you must first make an account, and then fill out a brief form indicating your intended use of the data. Once you have access, download the data for the following sites:
 - US-Ha1 
 - US-MOz
 - US-NR1
 - US-Var
We use the FULLSET hourly data product which should be named:
AMF_US-***_FLUXNET_FULLSET_HR_YYYY-YYYY_3-5.csv
Place this file for each site where the site ID correcsponds to the '***' in the file name in the `fluxnet_site_data` directory. Then run this script to create the artifact. In creating the artifacts, we trim down the data to a certain span of years to make the data more manageable.

License: CC BY 4.0
