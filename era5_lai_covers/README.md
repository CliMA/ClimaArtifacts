# ClimaLand LAI covers data
There are two files which are `era5_lai_covers_1.0x1.0.nc` and
`era5_lai_covers_0.25x0.25.nc`. The file `era5_lai_covers_1.0x1.0.nc` holds
data for low vegetation cover and high vegetation cover with a resolution of
1.0 degree. Similarly, the file `era5_lai_covers_0.25x0.25.nc` holds the same
field, but with a resolution of 0.25 degrees. The LAI covers are requested with
the date being 1/1/2008. According to the
[documentation](https://cds.climate.copernicus.eu/datasets/reanalysis-era5-single-levels?tab=overview),
LAI covers do not change with time.

For the `era5_lai_covers_1.0x1.0.nc` file, the fields are
- Latitude ("lat") (from -90.0 to 90.0 degrees at a resolution of 1.0 degree)
- Longitude ("lon") (from 0.0 to 359.00 degrees at a resolution of 1.0 degree)
- Low vegetation cover (lon, lat; "cvl")
- High vegetation cover (lon, lat; "cvh")

## Prerequisites
1. Python
2. Julia

## Usage
To recreate this artifact:
1. Clone this repository and navigate to this directory.
2. Follow the instructions [here](https://cds.climate.copernicus.eu/how-to-api)
to set up a CDS API personal access token.
3. Run the script (e.g. `python get_era5_lai_covers.py).
4. Run `julia --project=. create_artifact.jl`.
5. After the artifact is created, you can delete the NetCDF files used to make
   the plots.

## Post-processing
- Updating history for global attributes.
- Reverse latitude dimension so that the latitudes are in increasing order.
- Remove time dimension from data.

## Files
- `era5_lai_covers_0.25x0.25.nc` (549.5kB)
- `era5_lai_covers_1.0x1.0.nc` (8.3MB)

## Attribution
Hersbach, H. et al., (2018) was downloaded from the Copernicus Climate Change Service (2023). Our dataset contains modified Copernicus Climate Change Service information [2023]. Neither the European Commission nor ECMWF is responsible for any use that may be made of the Copernicus information or data it contains.

Copernicus Climate Change Service (2023): ERA5 hourly data on single levels from 1940 to present. Copernicus Climate Change Service (C3S) Climate Data Store (CDS), DOI: 10.24381/cds.adbb2d47 (Accessed on 29-SEP-2023)

Hersbach, H., Bell, B., Berrisford, P., Biavati, G., Horányi, A., Muñoz Sabater, J., Nicolas, J., Peubey, C., Radu, R., Rozum, I., Schepers, D., Simmons, A., Soci, C., Dee, D., Thépaut, J-N. (2018): ERA5 hourly data on single levels from 1940 to present. Copernicus Climate Change Service (C3S) Climate Data Store (CDS), DOI: 10.24381/cds.adbb2d47 , (Accessed on 29-SEP-2023)

Hersbach, H., Bell, B., Berrisford, P., Hirahara, S., Horányi, A., Muñoz-Sabater, J., Nicolas, J., Peubey, C., Radu, R., Schepers, D., Simmons, A., Soci, C., Abdalla, S., Abellan, X., Balsamo, G., Bechtold, P., Biavati, G., Bidlot, J., Bonavita, M., … Thépaut, J.-N. (2020). The ERA5 global reanalysis. Quarterly Journal of the Royal Meteorological Society, 146(730), 1999–2049. https://doi.org/10.1002/QJ.3803

## Licence
Please see [License to Use Copernicus Products](https://object-store.os-api.cci2.ecmwf.int/cci2-prod-catalogue/licences/licence-to-use-copernicus-products/licence-to-use-copernicus-products_b4b9451f54cffa16ecef5c912c9cebd6979925a956e3fa677976e0cf198c2c18.pdf) for more information.
