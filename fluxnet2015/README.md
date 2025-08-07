## Description
FLUXNET eddy covariance flux tower site data is used to validate ClimaLand on a site-level basis. The data must be manually downloaded from the FLUXNET website before running this script (see Setup for how to set up this artifact locally). **As such, the only functionality of `create_artifact.jl` is to create a hash assuming that the downloaded data is in a directory called `fluxnet2015`, then doing some metadata retrieval**. In the future, we may update this to directly download data from the remote source, but this can be cumbersome because as of now the data can only be downloaded sitewise using a web browser macro. The artifact which is stored on the Caltech HPC is 42 GB and was downloaded in May 2020. 

### Postprocessing
The only postprocessing that we do is metadata retrieval and cleaning from the FLX_AA directory. This contains site domain info as well as measurement heights that are useful for setting up site-level simulations. Currently, we look for and compile the following variables:
- Lat/long, UTC offset
- Annual mean temperature and precipitation
- Canopy height (averaged across measurements, if there are multiple)
- Atmospheric sensor height(s)
- Soil water sensor height(s)
- Soil temperature sensor height(s)

## Setup
Individual site data can be retrieved from https://fluxnet.org/data/fluxnet2015-dataset/. **This artifact expects FULLSET data, as opposed to leaner subsets**. To setup the repository structure, follow these steps:
1) Create a new repository called `fluxnet2015` 
2) Download individual FULLSET site data, which should go in subdirectories e.g., `/fluxnet2015/FLX_US-Var_FLUXNET2015_FULLSET_2000-2014_1-4`
3) Download the metadata files, which should go in a subdirectory, e.g., `fluxnet2015/FLX_AA-Flx_BIF_ALL_20200501`
4) In `create_artifact.jl`, change the `METADATA_FILE_PATH` variable to point to the correct metadata path. 
5) Run `create_artifact.jl` using `julia --project=. create_artifact.jl` and follow the instructions from the script to add the hash to your own `Overrides.toml` file.

License: CC BY 4.0

## Available sites
Available sites, as well as their corresponding temporal coverage, is contained in `available_sites.txt`. Each site is listed in the standard FLUXNET2015 naming format of "FLX_{sitename}_FLUXNET2015_FULLSET_{startyear}-{endyear}_{siteversion}-{codeversion}". These are also the names of the subdirectories within this artifact.

## Citation
Pastorello, G., Trotta, C., Canfora, E. et al. The FLUXNET2015 dataset and the ONEFlux processing pipeline for eddy covariance data. Sci Data 7, 225 (2020). https://doi.org/10.1038/s41597-020-0534-3
