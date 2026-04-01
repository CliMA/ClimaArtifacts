# ERA5 Lake Cover and Lake Depth

This artifact contains ERA5 lake cover and lake total depth data at 0.25 degree
resolution.

## Files
- `era5_lake_cover.nc` (~644KB): Fraction of grid cell covered by inland water
  bodies (lakes, reservoirs, rivers).
- `era5_lake_depth.nc` (~2.2MB): Lake total depth in meters.

Both files have the following structure:
- Latitude ("latitude"): from 90.0 to -90.0 degrees at 0.25 degree resolution
- Longitude ("longitude"): from 0.0 to 359.75 degrees at 0.25 degree resolution
- Valid time ("valid_time"): single time step

The data variables are:
- `cl` (valid_time, latitude, longitude): Lake cover (0-1) in `era5_lake_cover.nc`
- `dl` (valid_time, latitude, longitude): Lake total depth (m) in `era5_lake_depth.nc`

According to the
[documentation](https://cds.climate.copernicus.eu/datasets/reanalysis-era5-single-levels?tab=overview),
these fields are time-invariant.

## Prerequisites
1. Python (with `cdsapi` package)
2. Julia

## Usage
To recreate this artifact:
1. Clone this repository and navigate to this directory.
2. Follow the instructions [here](https://cds.climate.copernicus.eu/how-to-api)
   to set up a CDS API personal access token.
3. Run `python get_era5_lake_cover_and_depth.py` to download the raw data.
4. Run `julia --project=. create_artifact.jl` to create the artifact.

## Attribution
Hersbach, H. et al., (2018) was downloaded from the Copernicus Climate Change Service (2023). Our dataset contains modified Copernicus Climate Change Service information [2023]. Neither the European Commission nor ECMWF is responsible for any use that may be made of the Copernicus information or data it contains.

Copernicus Climate Change Service (2023): ERA5 hourly data on single levels from 1940 to present. Copernicus Climate Change Service (C3S) Climate Data Store (CDS), DOI: 10.24381/cds.adbb2d47 (Accessed on 31-MAR-2026)

Hersbach, H., Bell, B., Berrisford, P., Biavati, G., Horanyi, A., Munoz Sabater, J., Nicolas, J., Peubey, C., Radu, R., Rozum, I., Schepers, D., Simmons, A., Soci, C., Dee, D., Thepaut, J-N. (2018): ERA5 hourly data on single levels from 1940 to present. Copernicus Climate Change Service (C3S) Climate Data Store (CDS), DOI: 10.24381/cds.adbb2d47

Hersbach, H., Bell, B., Berrisford, P., Hirahara, S., Horanyi, A., Munoz-Sabater, J., Nicolas, J., Peubey, C., Radu, R., Schepers, D., Simmons, A., Soci, C., Abdalla, S., Abellan, X., Balsamo, G., Bechtold, P., Biavati, G., Bidlot, J., Bonavita, M., ... Thepaut, J.-N. (2020). The ERA5 global reanalysis. Quarterly Journal of the Royal Meteorological Society, 146(730), 1999-2049. https://doi.org/10.1002/QJ.3803

## Licence
Please see [License to Use Copernicus Products](https://object-store.os-api.cci2.ecmwf.int/cci2-prod-catalogue/licences/licence-to-use-copernicus-products/licence-to-use-copernicus-products_b4b9451f54cffa16ecef5c912c9cebd6979925a956e3fa677976e0cf198c2c18.pdf) for more information.
