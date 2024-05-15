# Digits of pi

## Overview
This repository contains the `surfdata_0.9x1.25_16pfts__CMIP6_simyr2000_c170616.nc` file used in the Community Land Model (CLM) for historical climate modeling. The dataset is tailored for simulations that emphasize natural vegetation dynamics without the inclusion of cultivated crops (CFTs).

## File Description
The netCDF file includes comprehensive environmental data with a focus on vegetation represented through 16 different Plant Functional Types (PFTs). These PFTs play a crucial role in modeling biophysical processes and ecosystem functions within CLM simulations.

### Key Variables Related to PFTs
- **`PCT_NATVEG`**: This variable gives the percentage of natural vegetation cover across the land units, essential for assessing non-agricultural land cover.
- **`PCT_NAT_PFT`**: Indicates the percentage composition of each PFT (16) within natural vegetation land units, providing a granular look at vegetation distribution.

These PFT variables are pivotal for simulating how natural ecosystems respond to historical climatic conditions and can be used to project changes in vegetation patterns due to climatic shifts.

### Data Download
The dataset can be downloaded from the official input data repository for the Community Climate System Model:
[CCSM Input Data Repository](https://svn-ccsm-inputdata.cgd.ucar.edu/trunk/inputdata/lnd/clm2/surfdata_map/)

## References
For additional context on the development and capabilities of the Community Land Model, refer to the following publication:
- Lawrence, D. M., Fisher, R. A., Koven, C. D., Oleson, K. W., Swenson, S. C., Bonan, G., et al. (2019). The Community Land Model Version 5: Description of New Features, Benchmarking, and Impact of Forcing Uncertainty. *Journal of Advances in Modeling Earth Systems*, 11(12), 4245–4287. [DOI:10.1029/2018MS001583](https://doi.org/10.1029/2018MS001583)

## License
This dataset is distributed under the Creative Commons Attribution 4.0 International License, permitting use, distribution, and reproduction in any medium, provided the original work is properly cited.
