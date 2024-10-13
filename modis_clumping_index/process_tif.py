################################################################################
# This module uses the rasterio library and NetCDF4 library to reproject the   #
# clumping index data derived from MODIS into a NetCDF file to be ingested by  #
# CliMA models. First, download the data in tiff format:                       #
#                                                                              #
# He, L., J.M. Chen, J. Pisek, C. Schaaf, and A.H. Strahler. 2017. Global      #
# 500-m Foliage Clumping Index Data Derived from MODIS BRDF, 2006. ORNL DAAC,  #
# Oak Ridge, Tennessee, USA. https://doi.org/10.3334/ORNLDAAC/1531             #
#                                                                              #
# https://daac.ornl.gov/cgi-bin/dsviewer.pl?ds_id=1531                         #
#                                                                              #
# This script will reproject the data from the MODIS sinusoidal projection to  #
# a standard lat/lon grid and save it as a NetCDF file.                        #
################################################################################

################################################################################
# IMPORTS                                                                      #
################################################################################

import sys
import rasterio
import netCDF4 as nc
import numpy as np
from rasterio.warp import calculate_default_transform, reproject, Resampling
from pyproj import CRS

################################################################################
# CONSTANTS                                                                    #
################################################################################

# Output file name
OUTPUT_FILE = "clumping_index.nc"

# Desired output coordinate reference system (CRS)
DEST_CRS = CRS.from_epsg(4326)

################################################################################
# FUNCTIONS                                                                    #
################################################################################


"""
read_tiff(filepath) -> (data, affine, crs)

Reads the data in from the tiff file and returns the data, affine 
transformation, and coordinate reference system for the data.
"""
def read_tiff(filepath):
    with rasterio.open(filepath) as src:
        data = src.read(1)      # Read the first band
        affine = src.transform  # Affine transformation
        crs = src.crs           # Coordinate reference system
    return data, affine, crs


"""
reproject_data(data, affine, crs) -> transform, width, height, reprojected_data

Reprojects the data from the source CRS to the destination CRS and returns the 
reprojected data.
"""
def reproject_data(data, affine, crs):
    # Calculate the transform and dimensions of the reprojected data
    with rasterio.open(sys.argv[1]) as src:
        transform, width, height = calculate_default_transform(
            crs, DEST_CRS, src.width, src.height, *src.bounds)

    # Initialize an array to hold the reprojected data
    reprojected_data = np.empty(shape=(height, width), dtype=np.float32)

    # Reproject the data
    reproject(
        source=data,
        destination=reprojected_data,
        src_transform=affine,
        src_crs=crs,
        dst_transform=transform,
        dst_crs=DEST_CRS,
        resampling=Resampling.nearest)

    return transform, width, height, reprojected_data


"""
write_nc(transform, width, height, reprojected_data)

Writes the reprojected data to a NetCDF file.
"""
def write_nc(transform, width, height, reprojected_data):
    # Create the output cdf file
    with nc.Dataset(OUTPUT_FILE, 'w', format='NETCDF4') as dst:

        # Define dimensions
        dst.createDimension('lat', height)
        dst.createDimension('lon', width)

        # Define variables
        latitudes = dst.createVariable('lat', np.float32, ('lat',))
        longitudes = dst.createVariable('lon', np.float32, ('lon',))
        ci = dst.createVariable('ci', np.float32, ('lat', 'lon'))

        # Set variable attributes
        latitudes.units = 'degrees_north'
        longitudes.units = 'degrees_east'
        ci.units = 'Unitless'

        # Calculate lat/lon values
        lats = np.linspace(transform[5], transform[5] + transform[4] * height,
                           height)
        lons = np.linspace(transform[2], transform[2] + transform[0] * width,
                           width)

        # Assign lat/lon values
        latitudes[:] = lats
        longitudes[:] = lons

        # Assign data
        ci[:, :] = reprojected_data


"""
main()

The main executable of this module reads the data from the tiff file, reprojects
the data, and writes the reprojected data to a NetCDF file.
"""
def main():
    assert(len(sys.argv) > 1), "Usage: python process_tif.py <tiff_path>"
    write_nc(*reproject_data(*read_tiff(sys.argv[1])))


if __name__ == "__main__":
    main()
