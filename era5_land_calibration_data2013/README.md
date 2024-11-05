# ClimaLand forcing data - ERA5 reanalysis data for 2021
This file holds one year of hourly data of a subset of ERA5 output fields.
The fields are
- Latitude ("lat") (from -90.0 to 90.0 degrees at a resolution of 1.0)
- Longitude ("lon") (from 0.0 to 360.00 degrees at a resolution of 1.0)
- Time ("time") (from TODO to TODO)
- SHF (lon, lat, time; "sshf")
- LHF (lon, lat, time; "slhf")
- ET (lon, lat, time; "e")
- LW_u
- SW_u
- Surface albedo (lon, lat, time; "fal")

## Prerequisites
1. Python environment with cdsapi installed.
2. Julia

## Usage
To recreate this artifact:
1. Create an account on https://cds.climate.copernicus.eu/.
2. Find your Personal Access Token at https://cds.climate.copernicus.eu/profile.
3. Navigate to this directory in the terminal.
4a. Using your python installation, run the script (e.g.
    `python get_era5_land_forcing_data2013.py YOUR_API_KEY YEAR_DESIRED`) with your API key
    from step 2 and 2013 for the year desired.
4b. If the files did not downloaded correctly (e.g. the script stopped for whatever reason),
    navigate to your requests on https://cds.climate.copernicus.eu/ and manually download
    them to this directory.
4. Run `julia --project=. create_artifact.jl`.

## Post-processing
- The attribute `_FILLVALUE` is removed from the attributes of the variables "longitude" and
  "latitude".
- For all variables beside time, longitude, and latitude, every attribute is removed except
  `standard_name`, `long_name`, `units`, `_FillValue`, and `missing_value`.
- Reverse latitude dimension so that latitude is increasing order.

## Files
- "era5_2013_0.9x1.25.nc" (~TODOGB)

## Attribution
Hersbach, H. et al., (2018) was downloaded from the Copernicus Climate Change Service (2023). Our dataset contains modified Copernicus Climate Change Service information [2023]. Neither the European Commission nor ECMWF is responsible for any use that may be made of the Copernicus information or data it contains.

Copernicus Climate Change Service (2023): ERA5 hourly data on single levels from 1940 to present. Copernicus Climate Change Service (C3S) Climate Data Store (CDS), DOI: 10.24381/cds.adbb2d47 (Accessed on 29-SEP-2023)

Hersbach, H., Bell, B., Berrisford, P., Biavati, G., Horányi, A., Muñoz Sabater, J., Nicolas, J., Peubey, C., Radu, R., Rozum, I., Schepers, D., Simmons, A., Soci, C., Dee, D., Thépaut, J-N. (2018): ERA5 hourly data on single levels from 1940 to present. Copernicus Climate Change Service (C3S) Climate Data Store (CDS), DOI: 10.24381/cds.adbb2d47 , (Accessed on 29-SEP-2023)

Hersbach, H., Bell, B., Berrisford, P., Hirahara, S., Horányi, A., Muñoz-Sabater, J., Nicolas, J., Peubey, C., Radu, R., Schepers, D., Simmons, A., Soci, C., Abdalla, S., Abellan, X., Balsamo, G., Bechtold, P., Biavati, G., Bidlot, J., Bonavita, M., … Thépaut, J.-N. (2020). The ERA5 global reanalysis. Quarterly Journal of the Royal Meteorological Society, 146(730), 1999–2049. https://doi.org/10.1002/QJ.3803

## Licence
Please see [License to Use Copernicus Products](https://object-store.os-api.cci2.ecmwf.int/cci2-prod-catalogue/licences/licence-to-use-copernicus-products/licence-to-use-copernicus-products_b4b9451f54cffa16ecef5c912c9cebd6979925a956e3fa677976e0cf198c2c18.pdf) for more information.
