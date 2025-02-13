import cdsapi
import os

def get_era5_lai_covers(res):
    dir_path = os.path.dirname(os.path.realpath(__file__))

    # for variable in lai_covers:
    dataset = "reanalysis-era5-single-levels"
    request = {
        "product_type": ["reanalysis"],
        "variable": [
            "low_vegetation_cover", "high_vegetation_cover"
        ],
        "year": ["2008"],
        "month": ["01"],
        "day": ["01"],
        "time": ["00:00"],
        "data_format": "netcdf",
        "download_format": "unarchived",
        'grid'  : [res, res]
    }

    client = cdsapi.Client(url="https://cds.climate.copernicus.eu/api")

    # Make file path name
    filepath = f"{dir_path}/era5_lai_covers_{res}x{res}_raw.nc"

    result = client.retrieve(dataset, request, filepath)
    return

if __name__ == "__main__":
    # Download lai cover data with a resolution of 0.25 and 1.0 degrees
    resolutions = [0.25, 1.0]
    for res in resolutions:
        get_era5_lai_covers(res)
