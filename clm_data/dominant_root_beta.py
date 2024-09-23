import netCDF4 as nc
import numpy as np

# Paths to input files
dominant_pft_file = 'dominant_PFT_map.nc'
clm_params_file =  'clm5_params.c171117.nc'
output_file = 'root_map.nc'
# Read the dominant PFT data
dominant_pft_dataset = nc.Dataset(dominant_pft_file, 'r')
dominant_pft = dominant_pft_dataset.variables['dominant_PFT'][:]
lat = dominant_pft_dataset.variables['LATIXY'][:]
lon = dominant_pft_dataset.variables['LONGXY'][:]
# read beta value for each PFT from clm_params_dataset
clm_params_dataset = nc.Dataset(clm_params_file, 'r')
beta_values = clm_params_dataset.variables['rootprof_beta'][:]
rooting_depth_map = np.zeros_like(dominant_pft, dtype=np.float32)

# Map the parameter values to the grid points based on the dominant PFT
for i in range(dominant_pft.shape[0]):
    for j in range(dominant_pft.shape[1]):
        pft_index = dominant_pft[i, j]
        if pft_index >= 0:
            # take zeroth row of beta_values because it matches the clm doc
            # calculate rooting_depth param from beta value
            rooting_depth_map[i, j] = (-1)/(100*np.log(beta_values[0][pft_index]))

# Create a new NetCDF file with the mapped variables
with nc.Dataset(output_file, 'w', format='NETCDF4') as output_dataset:
    # Define dimensions
    output_dataset.createDimension('lat', lat.shape[0])
    output_dataset.createDimension('lon', lon.shape[1])

    # Create variables
    latitudes = output_dataset.createVariable('lat', 'f4', ('lat',))
    longitudes = output_dataset.createVariable('lon', 'f4', ('lon',))
    rooting_depth_var = output_dataset.createVariable('rooting_depth', 'f4', ('lat', 'lon',), fill_value=np.nan)

    latitudes[:] = np.mean(lat, axis=1)  # Assuming LATIXY and LONGXY are 2D arrays
    longitudes[:] = np.mean(lon, axis=0)  # Averaging to get 1D lat/lon
    rooting_depth_var[:, :] = rooting_depth_map

    rooting_depth_var.long_name = 'Rooting Depth Parameter'
    rooting_depth_var.units = 'm'

print(f"NetCDF file '{output_file}' created successfully.")
