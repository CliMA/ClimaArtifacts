# WeatherQuest Initial Conditions (2010)

ERA5 reanalysis initial conditions for one representative date per season in
2010, preprocessed for initializing CliMA WeatherQuest hindcast runs.

For each date the artifact contains:
- `era5_raw_YYYYMMDD_0000.nc` — combined raw ERA5 download
- `era5_init_processed_internal_YYYYMMDD_0000.nc` — atmosphere IC
- `era5_land_processed_YYYYMMDD_0000.nc` — land IC
- `era5_bucket_processed_YYYYMMDD_0000.nc` — bucket IC
- `sst_processed_YYYYMMDD_0000.nc` — SST IC
- `sic_processed_YYYYMMDD_0000.nc` — sea ice IC
- `surf_processed_YYYYMMDD_0000.nc` — surface IC
- `aux_processed_YYYYMMDD_0000.nc` — auxiliary variables
- `albedo_processed_YYYYMMDD_0000.nc` — albedo IC

## Dates included

One date per season at 00:00 UTC, listed in [`dates.txt`](dates.txt).

## Usage

To recreate the artifact:

1. Set up the CDS API personal access token following the
   [instructions](https://cds.climate.copernicus.eu/how-to-api#install-the-cds-api-token).
2. Create and activate a Python virtual environment:

   ```bash
   python3 -m venv era5_env
   source era5_env/bin/activate
   pip install -r requirements.txt
   ```

3. Run the artifact creation script in the same terminal:

   ```bash
   julia --project create_artifact.jl
   ```

   This clones the WeatherQuest repository, downloads ERA5 data for all
   4 dates via the CDS API, and preprocesses them into CliMA initialization
   files. Downloads may take several hours depending on CDS queue times.

## Requirements

- Python >= 3.9 with dependencies from [`requirements.txt`](requirements.txt)
- CDS API key configured at `~/.cdsapirc`
- git (to clone WeatherQuest)
- ~2 GB of free disk space

## Reference

Hersbach, H. et al. (2023): ERA5 hourly data on pressure levels from 1940 to
present. Copernicus Climate Change Service (C3S) Climate Data Store (CDS),
DOI: [10.24381/cds.bd0915c6](https://doi.org/10.24381/cds.bd0915c6)

## Licence

Please see
[License to Use Copernicus Products](https://object-store.os-api.cci2.ecmwf.int/cci2-prod-catalogue/licences/licence-to-use-copernicus-products/licence-to-use-copernicus-products_b4b9451f54cffa16ecef5c912c9cebd6979925a956e3fa677976e0cf198c2c18.pdf)
for more information.
