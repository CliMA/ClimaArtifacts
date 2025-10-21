# ClimaLand forcing data - CRUJRAv2.5 reanalysis data for 1901 to 2023

This artifact contains 6-hourly CRUJRA forcing data for ClimaLand simulations from the years 1901 to 2023. The files are named `crujra_forcing_data_YEAR_0.5x0.5.nc`.

The CRUJRAv2.5 (Climatic Research Unit Japanese Reanalysis version 2.5) dataset provides meteorological forcing variables at 0.5° × 0.5° spatial resolution with 6-hourly temporal resolution.

## Data Structure

In `crujra_forcing_data_YEAR_0.5x0.5.nc`, the dimensions are:
- **Latitude** ("latitude"): 360 points from -89.75°S to 89.75°N at 0.5° resolution (stored in increasing order)
- **Longitude** ("longitude"): 720 points from 0.25°E to 359.75°E at 0.5° resolution (stored in increasing order)
- **Time** ("valid_time"): 6-hourly intervals

The fields are:
- **t2m** (valid_time, latitude, longitude): 2 metre temperature [K]
- **sp** (valid_time, latitude, longitude): Surface pressure [Pa]
- **d2m** (valid_time, latitude, longitude): 2 metre dewpoint temperature [K]
- **msdwlwrf** (valid_time, latitude, longitude): Mean surface downward long-wave radiation flux [W m⁻²]
- **msdwswrf** (valid_time, latitude, longitude): Mean surface downward short-wave radiation flux [W m⁻²]
- **msdrswrf** (valid_time, latitude, longitude): Mean surface direct short-wave radiation flux [W m⁻²]
- **mtpr** (valid_time, latitude, longitude): Mean total precipitation rate [kg m⁻² s⁻¹]
- **msr** (valid_time, latitude, longitude): Mean snowfall rate [kg m⁻² s⁻¹]
- **rainrate** (valid_time, latitude, longitude): Mean rain rate [kg m⁻² s⁻¹]
- **wind** (valid_time, latitude, longitude): Wind speed at lowest atmospheric level [m s⁻¹]

## Prerequisites

1. Julia (version 1.9 or higher recommended)
2. Access to CRUJRAv2.5 source data at `/net/sampo/data1/crujra/crujra_forcing_data/`
3. ~360GB of storage for the processed artifact (123 years × ~2.9GB per year)

## Usage

To recreate this artifact:

1. Clone the ClimaArtifacts repository and navigate to this directory:
   ```bash
   git clone https://github.com/CliMA/ClimaArtifacts.git
   cd ClimaArtifacts/crujra_forcing_data
   ```

2. Ensure Julia is installed and instantiate the project environment:
   ```bash
   julia --project=. -e 'using Pkg; Pkg.instantiate()'
   ```

3. The source data should be available in the directory structure:
   ```
   /net/sampo/data1/crujra/crujra_forcing_data/
   ├── crujra_2.5_1901/
   │   ├── crujra_forcing_data_1901_01.nc  (January)
   │   ├── crujra_forcing_data_1901_02.nc  (February)
   │   └── ...                              (12 monthly files)
   ├── crujra_2.5_1902/
   │   └── ...
   └── crujra_2.5_2023/
       └── ...
   ```

4. Run the artifact creation script:
   ```bash
   julia --project=. create_artifact.jl
   ```

The script will:
- Process each year's monthly files sequentially
- Stitch 12 monthly files into a single annual file
- Apply post-processing transformations
- Create the artifact tarball with proper metadata

## Post-processing

The post-processing steps applied to the data include:

1. **Temporal stitching**: Combine 12 monthly NetCDF files into a single annual file
2. **Latitude reversal**: Reverse latitude dimension so latitudes are in increasing order (-89.75°S to 89.75°N) for ClimaLand compatibility
3. **Attribute preservation**: Maintain critical variable attributes:
   - `units`: Physical units for each variable
   - `long_name`: Descriptive name
   - `standard_name`: CF-convention standard name (where applicable)
   - `_FillValue`: Missing value indicator (NaN32)
4. **Data type conversion**: Convert all variables to Float32 (except time dimension which remains Int64)
5. **Metadata enhancement**: Add global attributes documenting:
   - Source dataset (CRUJRAv2.5)
   - Processing history and timestamp
   - Grid resolution (0.5° × 0.5°)
   - CF Conventions compliance
   - Proper attribution and references

## Files

The artifact contains 123 annual files:
- `crujra_forcing_data_YEAR_0.5x0.5.nc` for years 1901 to 2023
- Each file is approximately 2.9 GB
- Total artifact size: ~360 GB

## Time Convention

- **Time units**: `seconds since 1901-01-01 00:00:00`
- **Calendar**: noleap (365-day calendar, no leap years)
- **Frequency**: 6-hourly (4 time steps per day)
- **Time steps per year**: ~1,460 (365 days × 4)

## Attribution

This dataset is derived from the CRU JRA-55 (CRUJRAv2.5) dataset, which combines:
- **CRU TS**: High-resolution gridded climate data from the Climatic Research Unit
- **JRA-55**: Japanese 55-year Reanalysis from the Japan Meteorological Agency

### Required Citations:

**Global Carbon Project:**

For more information and latest updates, visit: https://globalcarbonbudget.org/gcb-2024/

Friedlingstein, P., O'Sullivan, M., Jones, M. W., Andrew, R. M., Hauck, J., Landschützer, P., Le Quéré, C., Li, H., Luijkx, I. T., Olsen, A., Peters, G. P., Peters, W., Pongratz, J., Schwingshackl, C., Sitch, S., Canadell, J. G., Ciais, P., Jackson, R. B., Alin, S. R., Arneth, A., Arora, V., Bates, N. R., Becker, M., Bellouin, N., Berghoff, C. F., Bittig, H. C., Bopp, L., Cadule, P., Campbell, K., Chamberlain, M. A., Chandra, N., Chevallier, F., Chini, L. P., Colligan, T., Decayeux, J., Djeutchouang, L. M., Dou, X., Duran Rojas, C., Enyo, K., Evans, W., Fay, A. R., Feely, R. A., Ford, D. J., Foster, A., Gasser, T., Gehlen, M., Gkritzalis, T., Grassi, G., Gregor, L., Gruber, N., Gürses, Ö., Harris, I., Hefner, M., Heinke, J., Hurtt, G. C., Iida, Y., Ilyina, T., Jacobson, A. R., Jain, A. K., Jarníková, T., Jersild, A., Jiang, F., Jin, Z., Kato, E., Keeling, R. F., Klein Goldewijk, K., Knauer, J., Korsbakken, J. I., Lan, X., Lauvset, S. K., Lefèvre, N., Liu, Z., Liu, J., Ma, L., Maksyutov, S., Marland, G., Mayot, N., McGuire, P. C., Metzl, N., Monacci, N. M., Morgan, E. J., Nakaoka, S.-I., Neill, C., Niwa, Y., Nützel, T., Olivier, L., Ono, T., Palmer, P. I., Pierrot, D., Qin, Z., Resplandy, L., Roobaert, A., Rosan, T. M., Rödenbeck, C., Schwinger, J., Smallman, T. L., Smith, S. M., Sospedra-Alfonso, R., Steinhoff, T., Sun, Q., Sutton, A. J., Séférian, R., Takao, S., Tatebe, H., Tian, H., Tilbrook, B., Torres, O., Tourigny, E., Tsujino, H., Tubiello, F., van der Werf, G., Wanninkhof, R., Wang, X., Yang, D., Yang, X., Yu, Z., Yuan, W., Yue, X., Zaehle, S., Zeng, N., and Zeng, J. (2025). Global Carbon Budget 2024. *Earth System Science Data*, 17, 965–1039. https://doi.org/10.5194/essd-17-965-2025

**CRU TS dataset:**
Harris, I., Osborn, T.J., Jones, P. et al. (2020). Version 4 of the CRU TS monthly high-resolution gridded multivariate climate dataset. *Scientific Data*, 7, 109. https://doi.org/10.1038/s41597-020-0453-3

**JRA-55 Reanalysis:**
Kobayashi, S., Ota, Y., Harada, Y., Ebita, A., Moriya, M., Onoda, H., Onogi, K., Kamahori, H., Kobayashi, C., Endo, H., Miyaoka, K., and Takahashi, K. (2015). The JRA-55 Reanalysis: General Specifications and Basic Characteristics. *Journal of the Meteorological Society of Japan*, 93, 5-48. https://doi.org/10.2151/jmsj.2015-001

**CRUJRA dataset:**
Weedon, G.P., Balsamo, G., Bellouin, N., Gomes, S., Best, M.J., and Viterbo, P. (2014). The WFDEI meteorological forcing data set: WATCH Forcing Data methodology applied to ERA-Interim reanalysis data. *Water Resources Research*, 50, 7505-7514. https://doi.org/10.1002/2014WR015638

## License

This dataset inherits the licenses of both CRU TS and JRA-55:

- **CRU TS data**: Available under the Open Government License v3.0
- **JRA-55 data**: Free for research and educational purposes (see [JRA-55 Terms of Use](https://jra.kishou.go.jp/JRA-55/index_en.html#usage))

Users must comply with both licensing agreements and provide proper attribution when using this data.
