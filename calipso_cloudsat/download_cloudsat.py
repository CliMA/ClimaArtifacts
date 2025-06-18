import zipfile
import os
import sys
from pathlib import Path

from urllib.request import urlopen
from shutil import copyfileobj


def download_and_unzip_cloudsat():
    """Download the cloudsat data and save them to where this file is located"""
    dir_path = Path(os.path.dirname(os.path.realpath(__file__)))
    # Download data
    seasonal_10_zip = dir_path.joinpath("radarlidar_seasonal_10x10.zip")
    seasonal_2_5_zip = dir_path.joinpath("radarlidar_seasonal_2.5x2.5.zip")
    zip_files = [seasonal_10_zip, seasonal_2_5_zip]
    download_links = [
        "https://zenodo.org/records/12768877/files/radarlidar_seasonal_10x10.zip?download=1",
        "https://zenodo.org/records/12768877/files/radarlidar_seasonal_2.5x2.5.zip?download=1",
    ]
    for download_link, zip_file in zip(download_links, zip_files):
        with urlopen(download_link) as in_stream, open(zip_file, "wb") as out_file:
            copyfileobj(in_stream, out_file)

    # Find files and unzip them
    unzip_directory = dir_path.joinpath("radarlidar_seasonal_data")
    if not os.path.isdir(unzip_directory):
        os.mkdir(unzip_directory)
    for zip_file in [seasonal_10_zip, seasonal_2_5_zip]:
        with zipfile.ZipFile(str(zip_file), "r") as zip_ref:
            zip_ref.extractall(unzip_directory)
    return None


if __name__ == "__main__":
    download_and_unzip_cloudsat()
    print(
        "The data should be downloaded and stored in radarlidar_seasonal_data. You can now delete the zip files"
    )
