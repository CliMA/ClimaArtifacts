import cdsapi
import concurrent.futures
import itertools

client = cdsapi.Client()
dataset = "reanalysis-era5-pressure-levels"

def download_era5(variable, month):
    request = {
        "product_type": ["reanalysis"],
        "variable": variable,
        "year": ["2010"],
        "month": month,
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
        "data_format": "netcdf",
        "download_format": "unarchived",
        "grid": [2.0, 2.0]
    }
    filename = "era5_cloud_hourly_"+variable+"_2010"+month+".nc"
    print(filename)
    client.retrieve(dataset, request, filename)

if __name__ == "__main__":
    variables = ["fraction_of_cloud_cover", "specific_cloud_ice_water_content",
                "specific_cloud_liquid_water_content", "specific_humidity"]
    months = list(map(lambda x: str(x).zfill(2), range(1, 13)))
    variables_all = [r[0] for r in itertools.product(variables, months)]
    months_all = [r[1] for r in itertools.product(variables, months)]

    with concurrent.futures.ThreadPoolExecutor() as executor:
        executor.map(download_era5, variables_all, months_all)
