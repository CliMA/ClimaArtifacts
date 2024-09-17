import netCDF4 as nc
import numpy as np

# Paths to input files
dominant_pft_file = 'dominant_PFT_map.nc'
surface_file =  'surfdata_0.9x1.25_16pfts__CMIP6_simyr2000_c170616.nc'
output_file = 'mechanism_map.nc'

# Read the dominant PFT data
dominant_pft_dataset = nc.Dataset(dominant_pft_file, 'r')
dominant_pft = dominant_pft_dataset.variables['dominant_PFT'][:]
lat = dominant_pft_dataset.variables['LATIXY'][:]
lon = dominant_pft_dataset.variables['LONGXY'][:]


# Get photosynthesis mechanisms from surface data file
surface_dataset = nc.Dataset(surface_file, 'r')
pft_values = surface_dataset.variables['PCT_NAT_PFT'][:]
pft_dominant_values = np.argmax(pft_values, axis = 0)
c3_dominant_map = pft_dominant_values != 14
c3_dominant_map = c3_dominant_map.astype(float)
proportion_c3_map = np.ones_like(c3_dominant_map) - (pft_values[14]/100)



# Create a new NetCDF file with the mapped variables
with nc.Dataset(output_file, 'w', format='NETCDF4') as output_dataset:
    # Define dimensions
    output_dataset.createDimension('lat', lat.shape[0])
    output_dataset.createDimension('lon', lon.shape[1])

    # Create variables
    latitudes = output_dataset.createVariable('lat', 'f4', ('lat',))
    longitudes = output_dataset.createVariable('lon', 'f4', ('lon',))
    c3_dominant_var = output_dataset.createVariable('c3_dominant', 'f4', ('lat', 'lon',), fill_value=np.nan)
    proportion_c3_var = output_dataset.createVariable('c3_proportion', 'f4', ('lat', 'lon',), fill_value=np.nan)

    # Assign data to variables
    latitudes[:] = np.mean(lat, axis=1)  # Assuming LATIXY and LONGXY are 2D arrays
    longitudes[:] = np.mean(lon, axis=0)  # Averaging to get 1D lat/lon
    c3_dominant_var[:, :]  = c3_dominant_map
    proportion_c3_var[:, :]  = proportion_c3_map


    # Assign attributes
    latitudes.units = 'degrees_north'
    longitudes.units = 'degrees_east'
    c3_dominant_var.units = '0. = c4, 1. = c3'
    c3_dominant_var.long_name = 'c3 dominant'
    proportion_c3_var.long_name = 'Proportion of plants that are c3'
    proportion_c3_var.units = 'proportion c3'


print(f"NetCDF file '{output_file}' created successfully.")
