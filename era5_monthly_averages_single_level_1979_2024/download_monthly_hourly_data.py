############################################
# This script was inspired by CDSAPItools, which is deprecated.
# See here: https://github.com/e5k/CDSAPItools/tree/main

# This script downloads the data year by year. It queues 19 requests at a time and waits for them to finish.
# at a time. Once a request is finished, it downloads the data and updates the status in a csv file,
# and starts a new request. The csv isused to keep track of the status of the download.
# If the download is interrupted, the script can be resumed using the csv file
############################################

import cdsapi
import pandas as pd
import time
import argparse
import os

parser = argparse.ArgumentParser(description='Use cdsapi to download era5 mean monthly surface fluxes')
parser.add_argument('-k', '--key', help="CDS API KEY", type=str)
parser.add_argument('-r', '--resume', action='store_true')
parser.add_argument('-d', '--dir', help="download target dir", type=str)
args = parser.parse_args()

dataset = "reanalysis-era5-single-levels-monthly-means"

years = [str(year) for year in range(1979, 2025)]
if args.dir is None:
    output_dir = ""
else:
    output_dir = args.dir

SLEEP_TIME = 60
URL = 'https://cds.climate.copernicus.eu/api'
BASE_URL = "https://cds.climate.copernicus.eu/api/retrieve/v1/jobs/"

def submit_request(year):
    print("Submitting Request for data for year: ", year)
    if args.key is None:
        submit_client = cdsapi.Client(wait_until_complete=False, delete=False)
    else:
        submit_client = cdsapi.Client(wait_until_complete=False, delete=False, url=URL, key=args.key)
    request = {
    "product_type": ["monthly_averaged_reanalysis_by_hour_of_day"],
    "variable": [
        "mean_evaporation_rate",
        "mean_sub_surface_runoff_rate",
        "mean_surface_downward_long_wave_radiation_flux",
        "mean_surface_downward_short_wave_radiation_flux",
        "mean_surface_latent_heat_flux",
        "mean_surface_net_long_wave_radiation_flux",
        "mean_surface_net_short_wave_radiation_flux",
        "mean_surface_runoff_rate",
        "mean_surface_sensible_heat_flux",
        "total_column_water"
    ],
    "year": [year],
    "month": [
        "01", "02", "03",
        "04", "05", "06",
        "07", "08", "09",
        "10", "11", "12"
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
    "data_format": "netcdf_legacy",
    "download_format": "unarchived",
    "grid"  : [1.0, 1.0],
}
    r = submit_client.retrieve(dataset, request)
    return r.reply["request_id"]



# submit dummy request
if args.key is None:
    client = cdsapi.Client(wait_until_complete=False, delete=False)
else:
    client = cdsapi.Client(wait_until_complete=False, delete=False, url=URL, key=args.key)
r = client.retrieve('reanalysis-era5-pressure-levels', {
           "variable": "temperature",
           "pressure_level": "1000",
           "product_type": "reanalysis",
           "date": "2017-12-01/2017-12-31",
           "time": "12:00",
           "format": "grib"
       })
r.retry_options["maximum_tries"] = 9999
if args.resume:
    df = pd.read_csv("era5_download_status_hourly.csv", index_col=0)
else:
    df = pd.DataFrame()
    index = 0
    for year in years:
        df = pd.concat([df, pd.DataFrame({"year": year, "status": "not started", "request_id": ""}, index=[index])])
        index += 1
    df.to_csv("era5_download_status_hourly.csv")
while True:
    if all(df["status"] == "done"):
        print("All files are downloaded.")
        break
    not_started = df[df["status"] == "not started"]
    started = df[df["status"] == "started"]
    if started.shape[0] < 19 and not_started.shape[0] > 0:
        add_index = not_started.iloc[0].name
        df.iloc[add_index, 2] =  submit_request(df.iloc[add_index, 0])
        df.iloc[add_index, 1] = "started"
    for index, row in started.iterrows():
        r.url = BASE_URL + row["request_id"]
        r.update()
        if r.reply["state"] == "completed":

            df.iloc[index, 1] = "done"
            print("Downloaded data for year: ", df.iloc[index, 0], end='\r')
            try:
                r.download(os.path.join(output_dir, str(df.iloc[index, 0]) + ".nc"))
            except:
                print("Error downloading data for year: ", df.iloc[index, 0])
        elif r.reply["state"] == "failed":
            df.iloc[index, 1] = "failed"
            print("Failed to download data for year: ", df.iloc[index, 0])
        elif r.reply["state"] == "running":
            print("Data for year: ", df.iloc[index, 0], "is running.", end='\r')
        elif r.reply["state"] == "queued":
            print("Data for year: ", df.iloc[index, 0], "is queued.", end='\r')
        elif r.reply["state"] == "accepted":
            print("Data for year: ", df.iloc[index, 0], "is accepted.", end='\r')
        time.sleep(2)
    time.sleep(SLEEP_TIME)
    df.to_csv("era5_download_status_hourly.csv")



