import cdsapi
import argparse

parser = argparse.ArgumentParser(description='Use cdsapi to download era5 mean monthly surface fluxes')
parser.add_argument('-k', '--key', help="CDS API KEY", type=str)
parser.add_argument('-t', '--target', help="download target", type=str)
args = parser.parse_args()

URL = 'https://cds.climate.copernicus.eu/api'
dataset = "reanalysis-era5-single-levels-monthly-means"
request = {
    "product_type": ["monthly_averaged_reanalysis"],
    "year": [
        "1979", "1980", "1981",
        "1982", "1983", "1984",
        "1985", "1986", "1987",
        "1988", "1989", "1990",
        "1991", "1992", "1993",
        "1994", "1995", "1996",
        "1997", "1998", "1999",
        "2000", "2001", "2002",
        "2003", "2004", "2005",
        "2006", "2007", "2008",
        "2009", "2010", "2011",
        "2012", "2013", "2014",
        "2015", "2016", "2017",
        "2018", "2019", "2020",
        "2021", "2022", "2023",
        "2024"
    ],
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
    "variable": [
        "mean_surface_downward_long_wave_radiation_flux",
        "mean_surface_downward_short_wave_radiation_flux",
        "mean_surface_latent_heat_flux",
        "mean_surface_net_long_wave_radiation_flux",
        "mean_surface_net_short_wave_radiation_flux",
        "mean_surface_sensible_heat_flux",
        "mean_sub_surface_runoff_rate",
        "mean_surface_runoff_rate",
        "total_column_water"
    ]
}

if args.key is None:
    client = cdsapi.Client()
else:
    client = cdsapi.Client(url=URL, key=args.key)

if args.target is None or args.target == "":
    target = "era5_surface_fluxes_monthly_197901-202412.nc"
else:
    target = args.target

client.retrieve(dataset, request, target)
