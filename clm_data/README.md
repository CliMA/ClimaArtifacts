# Surface Data for CLM: Plant Functional Types

## Overview
This artifact contains scripts that process several Community Land Model (CLM) data files and maps vegetation properties based on Plant Functional Types (PFTs) and soil albedos based on soil color.
Below is a detailed description of each file and its purpose.

<!-- This repository contains the `surfdata_0.9x1.25_16pfts__CMIP6_simyr2000_c170616.nc` file used in the Community Land Model (CLM) for historical climate modeling. The dataset is tailored for simulations that emphasize natural vegetation dynamics without the inclusion of cultivated crops (CFTs). -->
## Usage
To recreate the artifact:
1. Create a python virtual environment
2. Activate the new virtual env
3. In the same terminal run `pip install -r requirements.txt`
4. In the same terminal run `julia --project create_artifact.jl`

### Requirements
- Python >=3.8

## Input Files

### 1. `surfdata_0.9x1.25_16pfts__CMIP6_simyr2000_c170616.nc` and `surfdata_0.125x0.125_16pfts_simyr2000_c151014.nc`
These netCDF files includes comprehensive environmental data with a focus on vegetation represented through different Plant Functional Types (PFTs). These PFTs play a crucial role in modeling biophysical processes and ecosystem functions within CLM simulations. It also contains soil color data, which is used to calculate soil alebdo. `surfdata_0.9x1.25_16pfts__CMIP6_simyr2000_c170616.nc` is on a 0.8x1.25 degree grid and is used to create the
clm_data artifact, while `surfdata_0.125x0.125_16pfts_simyr2000_c151014.nc` is on a 0.125x0.125 degree
grid and is used to create the clm_data_highres artifact. Both input files contain tge following PFTs:

- **Plant Functional Types**:
  - `not_vegetated`
  - `needleleaf_evergreen_temperate_tree`
  - `needleleaf_evergreen_boreal_tree`
  - `needleleaf_deciduous_boreal_tree`
  - `broadleaf_evergreen_tropical_tree`
  - `broadleaf_evergreen_temperate_tree`
  - `broadleaf_deciduous_tropical_tree`
  - `broadleaf_deciduous_temperate_tree`
  - `broadleaf_deciduous_boreal_tree`
  - `broadleaf_evergreen_shrub`
  - `broadleaf_deciduous_temperate_shrub`
  - `broadleaf_deciduous_boreal_shrub`
  - `c3_arctic_grass`
  - `c3_non-arctic_grass`
  - `c4_grass`

The `surfdata_0.125x0.125_16pfts_simyr2000_c151014.nc` also contains two additional PFTs:
`c3_crop` and `c3_irrigated`.
For information about each PFT and its parameters see the [CLM5 Docs](https://www2.cesm.ucar.edu/models/cesm2/land/CLM50_Tech_Note.pdf)

- **Variables Related to PFTs**:
    - `PCT_NATVEG`: This variable gives the percentage of natural vegetation cover across the land units, essential for assessing non-agricultural land cover.
    - `PCT_NAT_PFT`: Indicates the percentage composition of each PFT (15) within natural vegetation land units, providing a granular look at vegetation distribution.

These PFT variables are pivotal for simulating how natural ecosystems respond to historical climatic conditions and can be used to project changes in vegetation patterns due to climatic shifts.

- **Variables Related to Albedo**:
    - `SOIL_COLOR`: This variable gives the color class of soil across the land units. There are 20 soil classes.

- **Data Download**: The dataset can be downloaded from the official input data repository for the Community Climate System Model:
[CCSM Input Data Repository](https://svn-ccsm-inputdata.cgd.ucar.edu/trunk/inputdata/lnd/clm2/surfdata_map/)

### 2. `pft-physiology.c110225.nc`
Contains physiological parameters for each of the 21 PFTs in a previous version of CLM, when maximum rate of carboxylation did not depend on nitrogen content.

- **Plant Functional Types**:
In addition to the PFTs in the surface data inputs, this file also includes:
  - `corn`
  - `spring_wheat`
  - `winter_wheat`
  - `soybean`

  For information about each PFT and its parameters see the [CLM5 Docs](https://www2.cesm.ucar.edu/models/cesm2/land/CLM50_Tech_Note.pdf)

- **Variables**:
    - `taulnir`: Leaf transmittance: near-IR
    - `taulvis`: Leaf transmittance: visible
    - `tausnir`: Stem transmittance: near-IR
    - `tausvis`: Stem transmittance: visible
    - `vcmx25`: Maximum rate of carboxylation

- **Data Download:** The dataset can be downloaded
[here](https://svn-ccsm-inputdata.cgd.ucar.edu/trunk/inputdata/lnd/clm2/pftdata/pft-physiology.c110225.nc)

### 3. `clm5_params.c171117.nc`
Contains various parameters required by the CLM5 model.

- **Variables**:
    - `medlynslope`: Medlyn slope of conductance-photosynthesis relationship
    - `medlynintercept`: Medlyn intercept of conductance-photosynthesis relationship

- **Data Download**: The dataset can be downloaded
[here](https://svn-ccsm-inputdata.cgd.ucar.edu/trunk/inputdata/lnd/clm2/paramdata/clm5_params.c171117.nc)


## Output Files

### 1. `dominant_PFT_map.nc`
Contains the dominant PFT for each grid cell on the global grid.
- **Purpose**: Used as an input file for mapping the physiological parameters to the global grid based on the dominant PFT.

### 2. `vegetation_properties_map.nc`
Contains the mapped vegetation properties for each grid cell.
- **Contents**:
  - `medlynslope(lat, lon)`: Medlyn slope of conductance-photosynthesis relationship (kPa^0.5)
  - `medlynintercept(lat, lon)`: Medlyn intercept of conductance-photosynthesis relationship (umol m^-2 s^-1)
  - `rholnir(lat, lon)`: Leaf reflectance: near-IR (fraction)
  - `rholvis(lat, lon)`: Leaf reflectance: visible (fraction)
  - `taulnir(lat, lon)`: Leaf transmittance: near-IR (fraction)
  - `taulvis(lat, lon)`: Leaf transmittance: visible (fraction)
  - `tausnir(lat, lon)`: Stem transmittance: near-IR (fraction)
  - `tausvis(lat, lon)`: Stem transmittance: visible (fraction)
  - `vcmx25(lat, lon)`: Maximum rate of carboxylation (umol CO2/m**2/s)
  - `c3_dominant(lat, lon)` (0.0 and 1.0)
    - has a value of 1.0 when C3 is the dominant photosynthesis mechanism for that grid cell and a
value of 0.0 if C4 is dominant.
  - `c3_proportion(lat, lon)` (0 to 1)
    - has values in [0.0, 1.0] which represent the proportion of plants
    in a grid cell that use C3 photosynthesis.
  - `rooting_depth(lat, lon)` parameter for root_distribution (m)
    - Describes the depth where ~2/3 of the roots are above
  - `xl(lat, lon)` Leaf/stem orientation index

### 3. `soil_properties_map.nc`
Contains the mapped soil albedos for each grid cell.
- **Contents**:
  - `PAR_albedo_dry(lat, lon)`: The dry PAR albedo for the soil color at each grid cell (0 to 1)
  - `NIR_albedo_dry(lat, lon)`: The dry NIR albedo for the soil color at each grid cell (0 to 1)
  - `PAR_albedo_wet(lat, lon)`: The saturated PAR albedo for the soil color at each grid cell (0 to 1)
  - `NIR_albedo_wet(lat, lon)`: The saturated NIR albedo for the soil color at each grid cell (0 to 1)

## Scripts

### 1. `dominant_pft.py`
- **Description**: Script to determine the dominant PFT for each grid cell. The `-d` flag
runs the script on the high resolution inout file.
- **Purpose**: Processes the surface data to create the `dominant_PFT_map.nc` files.

### 2. `pft_variables.py`
- **Description**: Main script for mapping vegetation properties based on the dominant PFT.
The `-d` flag runs the script on the high resolution inout file.
- **Functionality**:
  - Calculates the dominant PFT for each grid cell using `surfdata_0.9x1.25_16pfts__CMIP6_simyr2000_c170616.nc` or
  `surfdata_0.125x0.125_16pfts_simyr2000_c151014.nc`.
  - Reads physiological parameters from `pft-physiology.c110225.nc`.
  - Maps these parameters to the global grid based on the dominant PFT.
  - Reads parameters from `clm5_params.c171117.nc` and maps them based on the dominant PFT/
  - Maps photosynthesis mechanism based on the dominant PFT.
    - If `c4_grass` is dominant, then the cell is marked as C4 dominant. If not
    the cell is marked as C3 dominant.
    - Maps proportion C3 mechanism by taking the sum of the percentages for all PFTS except `c4_grass`.
  - Finds the rooting beta parameter for the dominant pft, and then calculates and maps the `rooting_depth` parameter
  - Outputs the mapped parameters to `vegetation_properties_map.nc`.

### 3. `soil_variables.py`
- **Description**: Script for mapping soil properties based on the soil color. The `-d` flag
runs the script on the high resolution inout file.
- **Functionality**:
  - Finds the soil color for each grid cell using `surfdata_0.9x1.25_16pfts__CMIP6_simyr2000_c170616.nc` or
  `surfdata_0.125x0.125_16pfts_simyr2000_c151014.nc`.
  - Maps soil color at each grid cell to dry PAR albedo, dry NIR albedo, wet PAR alebdo, and wet NIR albedo

## References
For additional context on the development and capabilities of the Community Land Model, refer to the following publication:
- Lawrence, D. M., Fisher, R. A., Koven, C. D., Oleson, K. W., Swenson, S. C., Bonan, G., et al. (2019). The Community Land Model Version 5: Description of New Features, Benchmarking, and Impact of Forcing Uncertainty. *Journal of Advances in Modeling Earth Systems*, 11(12), 4245–4287. [DOI:10.1029/2018MS001583](https://doi.org/10.1029/2018MS001583)

For additional context on soil albedo and soil color schemes, refer to the following publication:
- Braghiere, R. K., Wang, Y., Gagné-Landmann, A., Brodrick, P. G., Bloom, A. A., Norton, A. J., Ma, S., Levine, P., Longo, M., Deck, K., Gentine, P., Worden, J. R., Frankenberg, C., & Schneider, T. (2023). The Importance of Hyperspectral Soil Albedo Information for Improving Earth System Model Projections. AGU Advances, 4(4), e2023AV000910. https://doi.org/10.1029/2023AV000910

## License
This dataset is distributed under the Creative Commons Attribution 4.0 International License, permitting use, distribution, and reproduction in any medium, provided the original work is properly cited.
