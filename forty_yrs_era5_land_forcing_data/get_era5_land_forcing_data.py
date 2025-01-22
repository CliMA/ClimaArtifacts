# API and command line interface
import cdsapi
import sys

# For making multiple requests at the same time
import concurrent.futures
from itertools import repeat
import copy

# OS operations such as manipulating file paths and get file size
import os.path
import os
import shutil

from unzip_era5_data import unzip_era_5_files

def get_era5_forcing_data_for(YOUR_API_KEY, year, months, res):
    """Get the ERA5 forcing data for ClimaLand for `months` from `year`."""
    # Make file path from year and months
    first_month = months[0]
    filename = f"era5_forcing_data_{year}_{first_month}.zip"

    dirpath = f"era_5_{year}"
    try:
        os.mkdir(dirpath)
        print(f"Directory '{directory_name}' created successfully.")
    except FileExistsError:
        print(f"Directory '{dirpath}' already exists.")
    except PermissionError:
        print(f"Permission denied: Unable to create '{dirpath}'.")
    except Exception as e:
        print(f"An error occurred: {e}")

    filepath = os.path.join(dirpath, filename)

    # If file exists, exit and do not make request
    if os.path.isfile(filepath):
        print(f"{filepath} already exists; will not request data")
        return None

    filename_inst = f"era5_forcing_data_{year}_{first_month}_inst.zip"
    filename_rate = f"era5_forcing_data_{year}_{first_month}_rate.zip"
    filepath_inst = os.path.join(dirpath, filename_inst)
    filepath_rate = os.path.join(dirpath, filename_rate)
    if os.path.isfile(filepath_inst) and os.path.isfile(filepath_rate):
        print(f"{filepath_inst} and {filepath_rate} already exist; will not request data")
        return None

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
        "leaf_area_index_low_vegetation"
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
    'grid'  : [res, res]
}
    client = cdsapi.Client(url="https://cds.climate.copernicus.eu/api", key=YOUR_API_KEY)
    result = client.retrieve(dataset, request, filepath)
    return None

def find_remaining_files(path, year_begin, year_end):
    """Get a list of the files that need to be downloaded for the years from `year_begin` to `year_end` - 1."""
# Get all existing files
    existing_files = []
    dirpaths = ["era_5_" + str(year) for year in range(int(year_begin), int(year_end))]
    for dirpath in dirpaths:
        if os.path.exists(dirpath):
            for path in os.listdir(dirpath):
                if os.path.isfile(os.path.join(dirpath, path)):
                    existing_files.append(os.path.join(dirpath, path))

    # Compute files we need to get
    files_to_get = []
    for (year, dirpath) in zip(range(int(year_begin), int(year_end)), dirpaths):
        for month in ["01", "02", "03", "04", "05", "06", "07", "08", "09", "10", "11", "12"]:
            files_to_get.append(os.path.join(dirpath, f"era5_forcing_data_{year}_{month}.zip"))

    # Find the files we can remove
    files_to_remove = []
    for existing_file in existing_files:
        if existing_file in files_to_get:
            files_to_remove.append(existing_file)
        else:
            if existing_file.endswith("_inst.zip") and existing_file.replace("inst", "rate") in existing_files:
                files_to_remove.append(existing_file.replace("_inst", ""))
    remaining_files = filter(lambda file: file not in files_to_remove, files_to_get)
    return list(remaining_files)

if __name__ == "__main__":
    API_KEY = str(sys.argv[1])
    year_begin = str(sys.argv[2])
    year_end = str(sys.argv[3])
    res = float(sys.argv[4])

    print(f"API_KEY: {API_KEY}")

    path = "."
    stat = shutil.disk_usage(path)
    free_space_in_GB = stat.free / (1024**3) # convert from bytes to GB

    # Find size of remaining files we need to download
    # One year is approximately 8.4GB for 1.0 degree resolution
    correction_factor = 1 / res**2
    required_space_in_GB = len(find_remaining_files(path, year_begin, year_end)) * ((8.4 * correction_factor) / 12.0)

    if free_space_in_GB < required_space_in_GB:
        print(f"Insufficient space, free space: {free_space_in_GB} GB and required space: {required_space_in_GB} GB")
        sys.exit()

    # Split the requests over all the months and submit them all at once; otherwise, we get the
    # error: Your request is too large, please reduce your selection.
    months_to_split_by = [["01"], ["02"], ["03"], ["04"], ["05"], ["06"], ["07"], ["08"], ["09"], ["10"], ["11"], ["12"]]
    months = []
    years = []
    for year in range(int(year_begin), int(year_end)):
        for i in range(len(months_to_split_by)):
            years.append(year)
        months += months_to_split_by

    # Convert to string because request does not works with integer values for years
    years = list(map(str, years))


    # This script requests data monthly as smaller datasets are prioritized in the queue.
    # However, a process can only have a single request at a time. To circumvent this, we
    # spawn 144 processes and assign a request to each process. This ensures that we always have
    # something in the queue. However, only a single request can be processed at a time which is
    #  the main bottleneck. Furthermore, the requests will not be processed if there are too many
    # completed requests. There is no workaround for this, as the CDS API does not support
    # deleting requests (see this [issue](https://github.com/ecmwf/cdsapi/issues/123)). To ensure
    # a request is always being processed, one can manually delete completed requests.
    # "all" is for downloading all the variables in one dataset
    with concurrent.futures.ProcessPoolExecutor(max_workers = 144) as executor:
        executor.map(get_era5_forcing_data_for, repeat(API_KEY), years, months, repeat(res))

    unzip_era_5_files()
