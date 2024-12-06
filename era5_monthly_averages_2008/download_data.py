import cdsapi
import argparse

parser = argparse.ArgumentParser(description='Use cdsapi to download era5 mean monthly surface fluxes')
parser.add_argument('-k', '--key', help="CDS API KEY", type=str)
args = parser.parse_args()

URL = 'https://cds.climate.copernicus.eu/api'

dataset = "reanalysis-era5-single-levels-monthly-means"
request = {
    "product_type": [
        "monthly_averaged_reanalysis",
        "monthly_averaged_reanalysis_by_hour_of_day"
    ],
    "variable": [
        "mean_evaporation_rate",
        "mean_surface_downward_long_wave_radiation_flux",
        "mean_surface_downward_short_wave_radiation_flux",
        "mean_surface_latent_heat_flux",
        "mean_surface_net_long_wave_radiation_flux",
        "mean_surface_net_short_wave_radiation_flux",
        "mean_surface_sensible_heat_flux",
        "mean_sub_surface_runoff_rate",
        "mean_surface_runoff_rate"
    ],
    "year": ["2008"],
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
    "grid"  : [1.0, 1.0]
}

if args.key is None:
    client = cdsapi.Client()
else:
    client = cdsapi.Client(url=URL, key=args.key)
r = client.retrieve(dataset, request, "era5_surface_fluxes_monthly_200801-200812.nc")