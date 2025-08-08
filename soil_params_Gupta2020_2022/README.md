# Soil parameters for hydrology
This artifact repackages data from two papers by S. Gupta et al.
Gupta, S., Lehmann, P., Bonetti, S., Papritz, A., and Or, D., (2020):
Global prediction of soil saturated hydraulic conductivity using random forest in a Covariate-based Geo Transfer Functions (CoGTF) framework.
Journal of Advances in Modeling Earth Systems, 13(4), e2020MS002242.
https://agupubs.onlinelibrary.wiley.com/doi/full/10.1029/2020MS002242

and
Gupta, S., Papritz, A., Lehmann, P., Hengl, T., Bonetti, S., & Or, D. (2022).
Global Mapping of Soil Water Characteristics Parameters—Fusing Curated Data with Machine Learning and Environmental Covariates.
Remote Sensing, 14(8), 1947.

The raw data can be downloaded at these links:
https://zenodo.org/records/3935359
https://zenodo.org/records/6348799


The raw data includes the log(saturated hydraulic conductivity) $K_{sat}$, the porosity $\nu$,
residual water content $\theta_{res}$, and van Genuchten parameters $\log (\alpha)$ and $n$ at four
depths and at 1km x 1km resolution.
The `create_artifacts.jl` script
- combines the data at different depths into a single file for each parameter
- creates a coarser version of the data by taking an average of the parameters within the cell, and applying a transformation (10^ for the log
variables, unit conversions) to that mean.
- saves the coarse resolution data to netcdf files.

License: Creative Commons Attribution 4.0 International