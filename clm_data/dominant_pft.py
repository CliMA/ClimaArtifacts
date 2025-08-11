import numpy as np
from netCDF4 import Dataset
import argparse

parser = argparse.ArgumentParser(description='Use cdsapi to download era5 mean monthly surface fluxes')
parser.add_argument('-d', '--detailed', help="use high res input data", action='store_true')
args = parser.parse_args()

def main(input_filename, output_filename):

    # Open the input NetCDF file
    ds = Dataset(input_filename, "r")

    # Read the latitude and longitude dimensions
    latitudes = ds.variables["LATIXY"][:, 0]
    longitudes = ds.variables["LONGXY"][0, :]

    # Read the PCT_NAT_PFT variable
    PCT_NAT_PFT = ds.variables["PCT_NAT_PFT"][:]

    # Print the dimensions of the PCT_NAT_PFT array
    print("Dimensions of PCT_NAT_PFT:", PCT_NAT_PFT.shape)

    # Expected dimensions
    natpft, lsmlat, lsmlon = PCT_NAT_PFT.shape

    # Find the dominant PFT per gridcell
    dominant_PFT = np.zeros((lsmlat, lsmlon), dtype=np.int32)

    for i in range(lsmlat):
        for j in range(lsmlon):
            # Get the PFT percentages for the current gridcell
            pft_percentages = PCT_NAT_PFT[:, i, j]

            # Find the index of the maximum percentage (dominant PFT)
            dominant_PFT[i, j] = np.argmax(pft_percentages)

    # Close the input NetCDF file
    ds.close()

    # Create the output NetCDF file
    ds_out = Dataset(output_filename, "w", format="NETCDF4")

    # Define the dimensions
    lat_dim = ds_out.createDimension("lat", lsmlat)
    lon_dim = ds_out.createDimension("lon", lsmlon)

    # Define the latitude and longitude variables
    lat_var = ds_out.createVariable("lat", np.float64, "lat")
    lon_var = ds_out.createVariable("lon", np.float64, "lon")

    # Write latitude and longitude data
    lat_var = latitudes
    lon_var = longitudes

    # Define the dominant PFT variable
    dominant_PFT_var = ds_out.createVariable("dominant_PFT", np.int32, ("lat", "lon"))

    # Add attributes to the variable
    dominant_PFT_var.long_name = "dominant plant functional type"
    dominant_PFT_var.units = "index"

    # Write data to the variable
    dominant_PFT_var[:, :] = dominant_PFT

    # Add global attributes
    ds_out.title = "Dominant Plant Functional Type per Gridcell"
    ds_out.source = "Generated from PCT_NAT_PFT in surfdata_0.9x1.25_16pfts__CMIP6_simyr2000_c170616.nc"
    ds_out.Conventions = "CF-1.8"

    # Close the output NetCDF file
    ds_out.close()

    print("NetCDF file with dominant PFT per gridcell has been created:", output_filename)

if __name__ == "__main__":
    if args.detailed:
        input_filename = "surfdata_0.125x0.125_16pfts_simyr2000_c151014.nc"
    else:
        input_filename = "surfdata_0.9x1.25_16pfts__CMIP6_simyr2000_c170616.nc"
    output_filename = "dominant_PFT_map.nc"
    main(input_filename, output_filename)
