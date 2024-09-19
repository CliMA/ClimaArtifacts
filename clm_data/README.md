# Surface Data for CLM: Plant Functional Types

## Overview
This artifact contains scripts that process several Community Land Model (CLM) data files and maps vegetation properties based on Plant Functional Types (PFTs).
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

### 1. `surfdata_0.9x1.25_16pfts__CMIP6_simyr2000_c170616.nc`
The netCDF file includes comprehensive environmental data with a focus on vegetation represented through 15 different Plant Functional Types (PFTs). These PFTs play a crucial role in modeling biophysical processes and ecosystem functions within CLM simulations.

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

  For information about each PFT and its parameters see the [CLM5 Docs](https://www2.cesm.ucar.edu/models/cesm2/land/CLM50_Tech_Note.pdf)

- **Key Variables Related to PFTs**:
    - `PCT_NATVEG`: This variable gives the percentage of natural vegetation cover across the land units, essential for assessing non-agricultural land cover.
    - `PCT_NAT_PFT`: Indicates the percentage composition of each PFT (15) within natural vegetation land units, providing a granular look at vegetation distribution.

These PFT variables are pivotal for simulating how natural ecosystems respond to historical climatic conditions and can be used to project changes in vegetation patterns due to climatic shifts.

- **Data Download**: The dataset can be downloaded from the official input data repository for the Community Climate System Model:
[CCSM Input Data Repository](https://svn-ccsm-inputdata.cgd.ucar.edu/trunk/inputdata/lnd/clm2/surfdata_map/)

### 2. `pft-physiology.c110225.nc`
Contains physiological parameters for each of the 21 PFTs in a previous version of CLM, when maximum rate of carboxylation did not depend on nitrogen content.

- **Plant Functional Types**:
In addition to the PFTs in `surfdata_0.9x1.25_16pfts__CMIP6_simyr2000_c170616.nc`, this file also includes:
  - `c3_crop`
  - `c3_irrigated`
  - `corn`
  - `spring_wheat`
  - `winter_wheat`
  - `soybean`

  For information about each PFT and its parameters see the [CLM5 Docs](https://www2.cesm.ucar.edu/models/cesm2/land/CLM50_Tech_Note.pdf)

- **Key Variables**:
    - `taulnir`: Leaf transmittance: near-IR
    - `taulvis`: Leaf transmittance: visible
    - `tausnir`: Stem transmittance: near-IR
    - `tausvis`: Stem transmittance: visible
    - `vcmx25`: Maximum rate of carboxylation

- **Data Download:** The dataset can be downloaded
[here](https://svn-ccsm-inputdata.cgd.ucar.edu/trunk/inputdata/lnd/clm2/pftdata/pft-physiology.c110225.nc)

### 3. `clm5_params.c171117.nc`
Contains various parameters required by the CLM5 model.

- **Key Variables**:
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
  - `taulnir(lat, lon)`: Leaf transmittance: near-IR (fraction)
  - `taulvis(lat, lon)`: Leaf transmittance: visible (fraction)
  - `tausnir(lat, lon)`: Stem transmittance: near-IR (fraction)
  - `tausvis(lat, lon)`: Stem transmittance: visible (fraction)
  - `vcmx25(lat, lon)`: Maximum rate of carboxylation (umol CO2/m**2/s)

### 3. `mechanism_map.nc`
Contains two variables which describe the photosynthesis mechanism for each grid cell.
`c3_dominant` has a value of 1.0 when C3 is the dominant photosynthesis mechanism for that grid cell and a
value of 0.0 if C4 is dominant. `c3_proportion` has values in [0.0, 1.0] which represent the proportion of plants
in a grid cell that use C3 photosynthesis.
- **Contents**:
  - `c3_dominant(lat, lon)` (0.0 and 1.0)
  - `c3_proportion(lat, lon)` (0 to 1)

## Scripts

### 1. `dominant_pft.py`
- **Description**: Script to determine the dominant PFT for each grid cell.
- **Purpose**: Processes the surface data to create the `dominant_PFT_map.nc` file.

### 2. `pft_variables.py`
- **Description**: Main script for mapping vegetation properties based on the dominant PFT.
- **Functionality**:
  - Reads the dominant PFT for each grid cell from `dominant_PFT_map.nc`.
  - Reads physiological parameters from `pft-physiology.c110225.nc`.
  - Maps these parameters to the global grid based on the dominant PFT.
  - Outputs the mapped parameters to `vegetation_properties_map.nc`.

### 3. `dominant_mechanism.py`
- **Description**: Script to determine the dominant photsynthesis mechanism for each grid cell.
- **Functionality**:
  - Reads the percent plant functional type for each grid cell (% of total plants in cell) from `surfdata_0.9x1.25_16pfts__CMIP6_simyr2000_c170616.nc`.
  - The `c4_grass` PFT is the only PFT that uses C4 photosynthesis
  - If the PFT with the highest percentage in a cell is not `c4_grass`, then the cell is marked as C3 dominant, and a 1.0 is placed in the grid cell in the output parameter `c3_dominant`. If the highest percentage is PFT `c4_grass`, a value of 0.0 is placed in the grid cell.
  - For `c3_proportion`, the value for each cell is the total percentage of the non-C4 PFTs, which is the sum of the percentages for all PFTS except `c4_grass`.
  - Outputs the mapped parameters to `mechanism_map.nc`
- **Purpose**: Processes the surface data to create the `mechanism_map.nc` file.

## References
For additional context on the development and capabilities of the Community Land Model, refer to the following publication:
- Lawrence, D. M., Fisher, R. A., Koven, C. D., Oleson, K. W., Swenson, S. C., Bonan, G., et al. (2019). The Community Land Model Version 5: Description of New Features, Benchmarking, and Impact of Forcing Uncertainty. *Journal of Advances in Modeling Earth Systems*, 11(12), 4245–4287. [DOI:10.1029/2018MS001583](https://doi.org/10.1029/2018MS001583)

## License
This dataset is distributed under the Creative Commons Attribution 4.0 International License, permitting use, distribution, and reproduction in any medium, provided the original work is properly cited.
