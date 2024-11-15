############################################
# This script was inspired by CDSAPItools, which is deprecated.
# See here: https://github.com/e5k/CDSAPItools/tree/main
############################################

import cdsapi
import pandas as pd
import time
import argparse

parser = argparse.ArgumentParser(description='Use cdsapi to download era5 mean monthly surface fluxes')
parser.add_argument('-k', '--key', help="CDS API KEY", type=str)
parser.add_argument('-r', '--resume', action='store_true')
parser.add_argument('-d', '--dir', help="download target dir", type=str)
args = parser.parse_args()

dataset = "reanalysis-era5-pressure-levels-monthly-means"

years = [str(year) for year in range(1979, 2025)]
if args.dir is None:
    output_dir = ""
else:
    output_dir = args.dir
URL = 'https://cds.climate.copernicus.eu/api'
SLEEP_TIME = 60
BASE_URL = "https://cds.climate.copernicus.eu/api/retrieve/v1/jobs/"

def submit_request(year):
    print("Submitting Request for data for year: ", year)
    if args.key is None:
        submit_client = cdsapi.Client(wait_until_complete=False, delete=False)
    else:
        submit_client = cdsapi.Client(wait_until_complete=False, delete=False, url=URL, key=args.key)
    request = {
    "product_type": ["monthly_averaged_reanalysis"],
    "variable": [
        "geopotential",
        "relative_humidity",
        "specific_humidity",
        "temperature",
        "u_component_of_wind",
        "v_component_of_wind",
        "vertical_velocity"
    ],
    "pressure_level": [
        "1", "2", "3",
        "5", "7", "10",
        "20", "30", "50",
        "70", "100", "125",
        "150", "175", "200",
        "225", "250", "300",
        "350", "400", "450",
        "500", "550", "600",
        "650", "700", "750",
        "775", "800", "825",
        "850", "875", "900",
        "925", "950", "975",
        "1000"
    ],
    "year": [year],
    "month": [
        "01", "02", "03",
        "04", "05", "06",
        "07", "08", "09",
        "10", "11", "12"
    ],
    "time": ["00:00"],
    "data_format": "netcdf",
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
    df = pd.read_csv("era5_download_status.csv", index_col=0)
else:
    df = pd.DataFrame()
    index = 0
    for year in years:
        df = pd.concat([df, pd.DataFrame({"year": year, "status": "not started", "request_id": ""}, index=[index])])
        index += 1
    df.to_csv("era5_download_status.csv")
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
                r.download(output_dir + str(df.iloc[index, 0]) + ".nc")
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
    df.to_csv("era5_download_status.csv")
