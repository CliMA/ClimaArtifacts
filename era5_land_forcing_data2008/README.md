# ClimaLand forcing data - ERA5 reanalysis data for 2008
There are three files which are `era5_2008_0.9x1.25.nc`, `era5_2008_0.9x1.25_lowres.nc`, and
`era5_2008_0.9x1.25_lai.nc`. The file `era5_2008_0.9x1.25_lowres.nc` is a lower resolution
version of `era5_2008_0.9x1.25.nc`.

The file `era5_2008_0.9x1.25.nc` holds one year of hourly data of a subset of ERA5 output
fields.
The fields are
- Latitude ("lat") (from -90.0 to 90.0 degrees at a resolution of 1.0 degree)
- Longitude ("lon") (from 0.0 to 359.00 degrees at a resolution of 1.0 degree)
- Time ("time") (hourly from 2008-01-01 to 2008-12-31)
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

The file `era5_2008_0.9x1.25_lai.nc` holds one year of weekly data for `lai_hv` and `lai_lv`.
- Latitude ("lat") (from -90.0 to 90.0 degrees at a resolution of 1.0)
- Longitude ("lon") (from 0.0 to 359.00 degrees at a resolution of 1.0)
- Time ("time") (weekly from 2008-01-01 to 2008-12-23; the date 2008-12-30 excluded as it
  does not constitute a full week)
- Leaf area index, high vegetation (lon, lat, time; "lai_hv")
- Leaf area index, low vegetation (lon, lat, time; "lai_lv")

## Prerequisites
1. Python
2. Julia

## Usage
To recreate this artifact:
1. Clone this repository and navigate to this directory.
2. Run `pip install virtualenv` if you do not already have virtualenv installed.
3. Run `virtualenv era5_download` to create an environment named `era5_download`.
4. Run `source era5_download/bin/activate` to enter the virtual environment.
5. Run `pip install -r requirements.txt` to install all the requirements.
6. Create an account on https://cds.climate.copernicus.eu/.
7. Find your Personal Access Token at https://cds.climate.copernicus.eu/profile.
8a. Using your virtual environment, run the script (e.g.
    `python get_era5_land_forcing_data_year.py YOUR_API_KEY YEAR_DESIRED`) with your API key
    from step 2 and 2008 for the year desired.
8b. If the files did not downloaded correctly (e.g. the script stopped for whatever reason),
    navigate to your requests on https://cds.climate.copernicus.eu/ and manually download
    them to this directory.
9. Run `julia --project=. create_artifact.jl`.

## Post-processing
- Updating history for global attributes.
- The attribute `_FILLVALUE` is removed from the attributes of the variables "longitude" and
  "latitude".
- For all variables beside time, longitude, and latitude, every attribute is removed except
  `standard_name`, `long_name`, `units`, `_FillValue`, and `missing_value`.
- Reverse latitude dimension so that the latitudes are in increasing order.
- All variables are stored as Float32 except for the time dimension which is
  stored as Int32 (these are converted to dates when loading them in Julia).
- To create a thinned version of the artifact, sample every eighth point for both latitude
  and longitude.

## Files
- `era5_2008_0.9x1.25.nc` (~21.32GB)
- `era5_2008_0.9x1.25_lowres.nc` (~346.87MB)
- `era5_2008_0.9x1.25_lai.nc` (~25.87MB)

## Attribution
Hersbach, H. et al., (2018) was downloaded from the Copernicus Climate Change Service (2023). Our dataset contains modified Copernicus Climate Change Service information [2023]. Neither the European Commission nor ECMWF is responsible for any use that may be made of the Copernicus information or data it contains.

Copernicus Climate Change Service (2023): ERA5 hourly data on single levels from 1940 to present. Copernicus Climate Change Service (C3S) Climate Data Store (CDS), DOI: 10.24381/cds.adbb2d47 (Accessed on 29-SEP-2023)

Hersbach, H., Bell, B., Berrisford, P., Biavati, G., Horányi, A., Muñoz Sabater, J., Nicolas, J., Peubey, C., Radu, R., Rozum, I., Schepers, D., Simmons, A., Soci, C., Dee, D., Thépaut, J-N. (2018): ERA5 hourly data on single levels from 1940 to present. Copernicus Climate Change Service (C3S) Climate Data Store (CDS), DOI: 10.24381/cds.adbb2d47 , (Accessed on 29-SEP-2023)

Hersbach, H., Bell, B., Berrisford, P., Hirahara, S., Horányi, A., Muñoz-Sabater, J., Nicolas, J., Peubey, C., Radu, R., Schepers, D., Simmons, A., Soci, C., Abdalla, S., Abellan, X., Balsamo, G., Bechtold, P., Biavati, G., Bidlot, J., Bonavita, M., … Thépaut, J.-N. (2020). The ERA5 global reanalysis. Quarterly Journal of the Royal Meteorological Society, 146(730), 1999–2049. https://doi.org/10.1002/QJ.3803

## Licence
Please see [License to Use Copernicus Products](https://object-store.os-api.cci2.ecmwf.int/cci2-prod-catalogue/licences/licence-to-use-copernicus-products/licence-to-use-copernicus-products_b4b9451f54cffa16ecef5c912c9cebd6979925a956e3fa677976e0cf198c2c18.pdf) for more information.
