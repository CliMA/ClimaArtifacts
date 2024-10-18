import netCDF4 as nc
import numpy as np

surface_file =  'surfdata_0.9x1.25_16pfts__CMIP6_simyr2000_c170616.nc'
output_file = 'soil_properties_map.nc'
# Table taken from CLM5.0 Tech Note Table 3.3 Dry and saturated soil albedos
# COLUMNS: Dry vis, Dry nir, Saturated vis, Saturated nir
SOIL_ALBEDOS = np.array([[0.36, 0.61, 0.25, 0.50],    # color = 1
                      [0.34, 0.57, 0.23,0.46],    # color = 2
                      [0.32, 0.53, 0.21, 0.42],    # color = 3
                      [0.31, 0.51, 0.20, 0.40],    # color = 4
                      [0.30, 0.49, 0.19, 0.38],    # color = 5
                      [0.29, 0.48, 0.18, 0.36],    # color = 6
                      [0.28, 0.45, 0.17, 0.34],    # color = 7
                      [0.27, 0.43, 0.16, 0.32],    # color = 8
                      [0.26, 0.41, 0.15, 0.30],    # color = 9
                      [0.25, 0.39, 0.14, 0.28],    # color = 10
                      [0.24, 0.37, 0.13, 0.26],    # color = 11
                      [0.23, 0.35, 0.12, 0.24],    # color = 12
                      [0.22, 0.33, 0.11, 0.22],    # color = 13
                      [0.20, 0.31, 0.10, 0.20],    # color = 14
                      [0.18, 0.29, 0.09, 0.18],    # color = 15
                      [0.16, 0.27, 0.08, 0.16],    # color = 16
                      [0.14, 0.25, 0.07, 0.14],    # color = 17
                      [0.12, 0.23, 0.06, 0.12],    # color = 18
                      [0.10, 0.21, 0.05, 0.10],    # color = 19
                      [0.08, 0.16, 0.04, 0.08]])   # color = 20

surface_dataset = nc.Dataset(surface_file, 'r')
soil_colors = surface_dataset.variables['SOIL_COLOR'][:]
lat = surface_dataset.variables['LATIXY'][:]
lon = surface_dataset.variables['LONGXY'][:]

PAR_albedo_dry_map = np.zeros_like(soil_colors, dtype=np.float32)
NIR_albedo_dry_map = np.zeros_like(soil_colors, dtype=np.float32)
PAR_albedo_wet_map = np.zeros_like(soil_colors, dtype=np.float32)
NIR_albedo_wet_map = np.zeros_like(soil_colors, dtype=np.float32)

# subtract one from soil color to match indices with SOIL_ALBEDOS array
def map_color_albedo(color_index, albedo_index):
    return SOIL_ALBEDOS[color_index - 1][albedo_index]

vmap = np.vectorize(map_color_albedo)

PAR_albedo_dry_map[:,:] = vmap(soil_colors, 0)
NIR_albedo_dry_map[:,:] = vmap(soil_colors, 1)
PAR_albedo_wet_map[:,:] = vmap(soil_colors, 2)
NIR_albedo_wet_map[:,:] = vmap(soil_colors, 3)

with nc.Dataset(output_file, 'w', format='NETCDF4') as output_dataset:
    # Define dimensions
    output_dataset.createDimension('lat', lat.shape[0])
    output_dataset.createDimension('lon', lon.shape[1])
    # Create variables
    latitudes = output_dataset.createVariable('lat', 'f4', ('lat',))
    longitudes = output_dataset.createVariable('lon', 'f4', ('lon',))
    PAR_albedo_dry_var = output_dataset.createVariable('PAR_albedo_dry', 'f4', ('lat', 'lon',), fill_value=np.nan)
    NIR_albedo_dry_var = output_dataset.createVariable('NIR_albedo_dry', 'f4', ('lat', 'lon',), fill_value=np.nan)
    PAR_albedo_wet_var = output_dataset.createVariable('PAR_albedo_wet', 'f4', ('lat', 'lon',), fill_value=np.nan)
    NIR_albedo_wet_var = output_dataset.createVariable('NIR_albedo_wet', 'f4', ('lat', 'lon',), fill_value=np.nan)
    # Assign data to variables
    latitudes[:] = np.mean(lat, axis=1)  # Assuming LATIXY and LONGXY are 2D arrays
    longitudes[:] = np.mean(lon, axis=0)  # Averaging to get 1D lat/lon
    PAR_albedo_dry_var[:,:] = PAR_albedo_dry_map
    NIR_albedo_dry_var[:,:] = NIR_albedo_dry_map
    PAR_albedo_wet_var[:,:] = PAR_albedo_wet_map
    NIR_albedo_wet_var[:,:] = NIR_albedo_wet_map
    # Assign attributes
    latitudes.units = 'degrees_north'
    longitudes.units = 'degrees_east'
    PAR_albedo_dry_var.units = "[0 to 1]"
    PAR_albedo_dry_var.long_name = "PAR albedo dry"
    NIR_albedo_dry_var.units = "[0 to 1]"
    NIR_albedo_dry_var.long_name = "NIR albedo dry"
    PAR_albedo_wet_var.units = "[0 to 1]"
    PAR_albedo_wet_var.long_name = "PAR albedo saturated"
    NIR_albedo_wet_var.units = "[0 to 1]"
    NIR_albedo_wet_var.long_name = "NIR albedo saturated"

print(f"NetCDF file '{output_file}' created successfully.")
