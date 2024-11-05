import concurrent.futures
import cdsapi
import sys
from itertools import repeat

def get_era5_calibration_for(YOUR_API_KEY, year, months):
    """Get the ERA5 calibration data for ClimaLand for `months` from `year`."""
    dataset = "reanalysis-era5-single-levels"
    request = {
    "product_type": ["monthly_averaged_reanalysis"],
    "variable": [
        "surface_latent_heat_flux",
        "surface_sensible_heat_flux",
        "evaporation",
        "forecast_albedo"
    ],
    "year": ["2013"],
    "month": [
        "01", "02", "03",
        "04", "05", "06",
        "07", "08", "09",
        "10", "11", "12"
    ],
    "time": ["00:00"],
    "data_format": "netcdf",
    "download_format": "unarchived"
}
    client = cdsapi.Client(url="https://cds.climate.copernicus.eu/api", key=YOUR_API_KEY)
    client.retrieve(dataset, request).download()

if __name__ == "__main__":
    API_KEY = str(sys.argv[1])
    year = str(sys.argv[2])

    print(f"API_KEY: {API_KEY}")

    # Split the requests over all the months and submit them all at once; otherwise, we get the
    # error: Your request is too large, please reduce your selection.
    months = [["01", "02", "03","04"], ["05", "06", "07", "08"], ["09", "10", "11", "12"]]
    with concurrent.futures.ThreadPoolExecutor() as executor:
        executor.map(get_era5_forcing_data_for, repeat(API_KEY), repeat(year), months)
