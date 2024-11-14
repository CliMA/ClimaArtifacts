import concurrent.futures
import cdsapi
import sys
from itertools import repeat

def get_era5_forcing_data_for(YOUR_API_KEY, year, months):
    """Get the ERA5 forcing data for ClimaLand for `months` from `year`."""
    dataset = "reanalysis-era5-single-levels"
    request = {
    "product_type": ["reanalysis"],
    "variable": [
        "10m_u_component_of_wind",
        "10m_v_component_of_wind",
        "2m_dewpoint_temperature",
        "2m_temperature",
        "surface_pressure",
        "mean_snowfall_rate",
        "mean_surface_direct_short_wave_radiation_flux",
        "mean_surface_downward_long_wave_radiation_flux",
        "mean_surface_downward_short_wave_radiation_flux",
        "mean_total_precipitation_rate",
        "leaf_area_index_high_vegetation",
        "leaf_area_index_low_vegetation",
    ],
    "year": [year],
    "month": months,
    "day": [
        "01", "02", "03",
        "04", "05", "06",
        "07", "08", "09",
        "10", "11", "12",
        "13", "14", "15",
        "16", "17", "18",
        "19", "20", "21",
        "22", "23", "24",
        "25", "26", "27",
        "28", "29", "30",
        "31"
    ],
    "time": [
        "00:00", "01:00", "02:00",
        "03:00", "04:00", "05:00",
        "06:00", "07:00", "08:00",
        "09:00", "10:00", "11:00",
        "12:00", "13:00", "14:00",
        "15:00", "16:00", "17:00",
        "18:00", "19:00", "20:00",
        "21:00", "22:00", "23:00"
    ],
    "data_format": "netcdf",
    "download_format": "unarchived",
    'grid'  : [1.0, 1.0]
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
