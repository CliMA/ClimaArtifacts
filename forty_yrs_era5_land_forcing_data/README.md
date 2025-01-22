# ClimaLand forcing data - ERA5 reanalysis data for 1979 to 2024

This artifact contains hourly ERA5 forcing data for ClimaLand simulations from the years
1979 to 2024. The files are named `era5_YEAR_1.0x1.0.nc` and `era5_YEAR_1.0x1.0_lai.nc`. For
2024, the latest datetime is 2024-11-08T01:00:00 because the dataset is downloaded on
2024-11-13 at 01:50.

In `era5_YEAR_1.0x1.0.nc`, the fields are
- Latitude ("lat") (from -90.0 to 90.0 degrees at a resolution of 1.0 degree)
- Longitude ("lon") (from 0.0 to 359.00 degrees at a resolution of 1.0 degree)
- Time ("time")
- 10 metre U wind component (lon, lat, time; "u10")
- 10 metre V wind component (lon, lat, time; "v10")
- Dew point temperature at 2 meters (lon, lat, time; "d2m")
- Temperature at 2 meters (lon, lat, time; "t2m")
- Surface air pressure (lon, lat, time; "sp")
- Mean snowfall rate (lon, lat, time; "msr")
- Mean surface direct short wave radiation flux (lon, lat, time; "msdrswrf")
- Mean surface downward long wave radiation flux (lon, lat, time; "msdwlwrf")
- Mean surface downward short wave radiation flux (lon, lat, time; "msdwswrf")
- Mean total precipitation rate (lon, lat, time; "mtpr")

Note that the last five fields ("msr", "msdrswrf", "msdwlwrf", "msdwswrf", "mtpr") are now
renamed to "avg_tsrwe", "avg_sdirswrf", "avg_sdlwrf", "avg_sdswrf", and "avg_tprate" when
postprocessing the data. These fields are renamed to what they were before to maintain
backward compatibility.

The file `era5_YEAR_1.0x1.0_lai.nc` holds one year of weekly data for `lai_hv` and `lai_lv`.
- Latitude ("lat") (from -90.0 to 90.0 degrees at a resolution of 1.0)
- Longitude ("lon") (from 0.0 to 359.00 degrees at a resolution of 1.0)
- Time ("time")
- Leaf area index, high vegetation (lon, lat, time; "lai_hv")
- Leaf area index, low vegetation (lon, lat, time; "lai_lv")

## Prerequisites
1. Python
2. Julia
3. ~1.5TB of storage size for download and postprocessing the data

## Usage
To recreate this artifact:
1. Clone this repository and navigate to this directory.
2. Run `pip install virtualenv` if you do not already have virtualenv installed.
3. Run `virtualenv era5_download` to create an environment named `era5_download`.
4. Run `source era5_download/bin/activate` to enter the virtual environment.
5. Run `pip install -r requirements.txt` to install all the requirements.
6. Create an account on https://cds.climate.copernicus.eu/.
7. Find your Personal Access Token at https://cds.climate.copernicus.eu/profile.
8a. Using your virtual environment, run the script (e.g. `python
    get_era5_land_forcing_data.py YOUR_API_KEY YEAR_START YEAR_END RES`) with your API key
    from step 2, your desired starting and ending years, and the desired resolution for the
    longitude and latitude. Note that YEAR_END is not included when download data. For
    instance, to download ERA5 data for the years 1979 to 2024 with a resolution of 1.0
    degree, run `python get_era5_land_forcing_data.py YOUR_API_KEY 1979 2025 1.0`. See the
    next step for checking if any file is corrupted or missing.
8b. Check for corrupted and missing files using `julia
    find_corrupted_and_missing_nc_files.jl YEAR_START YEAR_END LAST_MONTH`. Note that
    YEAR_END is included. For instance, to check corrupted files for the years 1979 to 2024
    excluding the last month of 2024, then run
    `julia --project=. find_corrupted_and_missing_nc_files.jl 1979 2024 11`. We say that a
    file is corrupted if
      1. Variables are missing
      2. It cannot be open using NCDatasets
      3. Duplicated points in time dimension
      4. Time dimension is not sorted
    After deleting the corrupted files, run the same command in step 8a. Repeat step 8
    until all files are verified to be correct by
    `julia find_corrupted_and_missing_nc_files.jl YEAR_START YEAR_END LAST_MONTH`. The issue
    of corruption of the dataset is due to the Copernicus backend. The frequency of errors
    differ depending on what dataset and combination of variables are being downloaded.
9. Run `julia --project=. create_artifact.jl RES` to create the artifact, where `RES` is the
   resolution used in step 8a.

## Post-processing
- Updating history for global attributes.
- The attribute `_FILLVALUE` is removed from the attributes of the variables "longitude" and
  "latitude".
- For all variables beside time, longitude, and latitude, every attribute is removed except
  `standard_name`, `long_name`, `units`, `_FillValue`, and `missing_value`.
- Reverse latitude dimension so that the latitudes are in increasing order.
- All variables are stored as Float32 except for the time dimension which is stored as Int32
  (these are converted to dates when loading them in Julia).
- Renaming the fields "avg_tsrwe", "avg_sdirswrf", "avg_sdlwrf", "avg_sdswrf", and
  "avg_tprate" to "msr", "msdrswrf", "msdwlwrf", "msdwswrf", and "mtpr" respectively.

To be compatiable with the ClimaLand simulation, the postprocessing of reversing the
latitude dimension is necessary. Furthermore, datasets downloaded separately, such as with
the rate and instanteous variables, are stitched together, so that NCDatasets can read the
stitched dataset as opposed to reading the datasets separately. Hence, to be able to read
the raw ERA5 datasets, the ClimaLand simulation must support automatic reversing of the
latitude dimension, the reversing of the corresponding axis of the data of the variables,
and reading datasets containing different variables and different times.

## Files
The files included are `era5_YEAR_1.0x1.0.nc` and `era5_YEAR_1.0x1.0_lai.nc` for the years
1979 to 2024. The total size of the artifact is around 1TB.

## Code workarounds
This script requests data monthly as smaller datasets are prioritized in the queue.
However, a process can only have a single request at a time. To circumvent this, we
spawn 144 processes and assign a request to each process. This ensures that we always have
something in the queue. However, only a single request can be processed at a time which is
the main bottleneck. Furthermore, the requests will not be processed if there are too many
completed requests. There is no workaround for this, as the CDS API does not support
deleting requests (see this [issue](https://github.com/ecmwf/cdsapi/issues/123)). To ensure
a request is always being processed, one can manually delete completed requests.

In some cases, data can be corrupted in the sense that the datasets are missing
variables. The script `find_corrupted_and_missing_nc_files.jl` can be used to determine
whether a file is corrupted or not.

## Attribution
Hersbach, H. et al., (2018) was downloaded from the Copernicus Climate Change Service (2023). Our dataset contains modified Copernicus Climate Change Service information [2023]. Neither the European Commission nor ECMWF is responsible for any use that may be made of the Copernicus information or data it contains.

Copernicus Climate Change Service (2023): ERA5 hourly data on single levels from 1940 to present. Copernicus Climate Change Service (C3S) Climate Data Store (CDS), DOI: 10.24381/cds.adbb2d47 (Accessed on 29-SEP-2023)

Hersbach, H., Bell, B., Berrisford, P., Biavati, G., Horányi, A., Muñoz Sabater, J., Nicolas, J., Peubey, C., Radu, R., Rozum, I., Schepers, D., Simmons, A., Soci, C., Dee, D., Thépaut, J-N. (2018): ERA5 hourly data on single levels from 1940 to present. Copernicus Climate Change Service (C3S) Climate Data Store (CDS), DOI: 10.24381/cds.adbb2d47 , (Accessed on 29-SEP-2023)

Hersbach, H., Bell, B., Berrisford, P., Hirahara, S., Horányi, A., Muñoz-Sabater, J., Nicolas, J., Peubey, C., Radu, R., Schepers, D., Simmons, A., Soci, C., Abdalla, S., Abellan, X., Balsamo, G., Bechtold, P., Biavati, G., Bidlot, J., Bonavita, M., … Thépaut, J.-N. (2020). The ERA5 global reanalysis. Quarterly Journal of the Royal Meteorological Society, 146(730), 1999–2049. https://doi.org/10.1002/QJ.3803

## Licence
Please see [License to Use Copernicus Products](https://object-store.os-api.cci2.ecmwf.int/cci2-prod-catalogue/licences/licence-to-use-copernicus-products/licence-to-use-copernicus-products_b4b9451f54cffa16ecef5c912c9cebd6979925a956e3fa677976e0cf198c2c18.pdf) for more information.
