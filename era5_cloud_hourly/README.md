# Cloud data, monthly means, 2010

This artifact repackages data coming from [ERA5 reanalysis](https://cds.climate.copernicus.eu/datasets/reanalysis-era5-pressure-levels-monthly-means?tab=overview) 
and contains monthly averaged cloud properties in 2010.

The input file is defined in pressure coordinates. We convert this into altitude over mean-sea level
using $P = P^*exp(-z / H)$ with scale height $H$. We assume $P^* = 1e5$ (Pa) and $H = 7000$ (m). The output 
is a NetCDF file that contains cloud fraction, cloud liquid water content (kg/kg), and cloud ice water content (kg/kg) 
defined on a lon-lat-z-time grid.

## Usage
To recreate the artifact:
1. Set up the CDI APS personal access token following the [instruction](https://cds.climate.copernicus.eu/how-to-api#install-the-cds-api-token)
1. Create a python virtual environment
2. Activate the new virtual env
3. In the same terminal run `pip install -r requirements.txt`
4. In the same terminal run `julia --project create_artifact.jl`

## Requirements
- Python >= 3

## Reference
Hersbach, H., Bell, B., Berrisford, P., Biavati, G., Horányi, A., Muñoz Sabater, J., Nicolas, J., Peubey, C., Radu, R., Rozum, I., Schepers, D., Simmons, A., Soci, C., Dee, D., Thépaut, J-N. (2023): ERA5 monthly averaged data on pressure levels from 1940 to present. Copernicus Climate Change Service (C3S) Climate Data Store (CDS), DOI: 10.24381/cds.6860a573 (Accessed on 08-Oct-2024)

## Licence
Please see [License to Use Copernicus Products](https://object-store.os-api.cci2.ecmwf.int/cci2-prod-catalogue/licences/licence-to-use-copernicus-products/licence-to-use-copernicus-products_b4b9451f54cffa16ecef5c912c9cebd6979925a956e3fa677976e0cf198c2c18.pdf) for more information.