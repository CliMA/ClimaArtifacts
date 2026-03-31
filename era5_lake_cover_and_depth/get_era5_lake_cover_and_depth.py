import cdsapi
import os


def get_era5_lake_data(variable, filename):
    dir_path = os.path.dirname(os.path.realpath(__file__))

    dataset = "reanalysis-era5-single-levels"
    request = {
        "product_type": ["reanalysis"],
        "variable": [variable],
        "year": ["2008"],
        "month": ["01"],
        "day": ["01"],
        "time": ["00:00"],
        "data_format": "netcdf",
        "download_format": "unarchived",
        "grid": [0.25, 0.25],
    }

    client = cdsapi.Client(url="https://cds.climate.copernicus.eu/api")

    filepath = f"{dir_path}/{filename}"
    result = client.retrieve(dataset, request, filepath)
    return


if __name__ == "__main__":
    get_era5_lake_data("lake_cover", "era5_lake_cover_raw.nc")
    get_era5_lake_data("lake_total_depth", "era5_lake_depth_raw.nc")
