## Description
FLUXNET eddy covariance flux tower site data is used to validate ClimaLand on a site-level basis. The data must be manually downloaded from the FLUXNET website before running this script. **As such, the only functionality of `create_artifact.jl` is to create a hash assuming that the downloaded data is in a directory called `fluxnet2015`**. In the future, we may update this to directly download data from the remote source, but this can be cumbersome because as of now the data can only be downloaded sitewise using a web browser macro. No preprocessing is done. This is an undownloadable artifact (42 GB). 

Individual site data can be retrieved from https://fluxnet.org/data/fluxnet2015-dataset/ 

License: CC BY 4.0

## Available sites
Available sites, as well as their corresponding temporal coverage, is contained in `available_sites.txt`. Each site is listed in the standard FLUXNET2015 naming format of "FLX_{sitename}_FLUXNET2015_FULLSET_{startyear}-{endyear}_{siteversion}-{codeversion}". These are also the names of the subdirectories within this artifact.

## Citation
Pastorello, G., Trotta, C., Canfora, E. et al. The FLUXNET2015 dataset and the ONEFlux processing pipeline for eddy covariance data. Sci Data 7, 225 (2020). https://doi.org/10.1038/s41597-020-0534-3
