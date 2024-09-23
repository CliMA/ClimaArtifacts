import netCDF4 as nc
import numpy as np

# Paths to input files
dominant_pft_file = 'dominant_PFT_map.nc'
clm_params_file = 'clm5_params.c171117.nc'
pft_physiology_file = 'pft-physiology.c110225.nc'
output_file = 'vegetation_properties_map.nc'

# Read the dominant PFT data
dominant_pft_dataset = nc.Dataset(dominant_pft_file, 'r')
dominant_pft = dominant_pft_dataset.variables['dominant_PFT'][:]
lat = dominant_pft_dataset.variables['LATIXY'][:]
lon = dominant_pft_dataset.variables['LONGXY'][:]

# Read the medlynslope and medlynintercept values from the CLM parameters file
clm_params_dataset = nc.Dataset(clm_params_file, 'r')
medlynslope_values = clm_params_dataset.variables['medlynslope'][:]
medlynintercept_values = clm_params_dataset.variables['medlynintercept'][:]

# Read the physiological parameters from the pft-physiology file
pft_physiology_dataset = nc.Dataset(pft_physiology_file, 'r')
rholnir_values = pft_physiology_dataset.variables['rholnir'][:]
rholvis_values = pft_physiology_dataset.variables['rholvis'][:]
taulnir_values = pft_physiology_dataset.variables['taulnir'][:]
taulvis_values = pft_physiology_dataset.variables['taulvis'][:]
tausnir_values = pft_physiology_dataset.variables['tausnir'][:]
tausvis_values = pft_physiology_dataset.variables['tausvis'][:]
vcmx25_values = pft_physiology_dataset.variables['vcmx25'][:]

# Create arrays to store the mapped values for each grid point
medlynslope_map = np.zeros_like(dominant_pft, dtype=np.float32)
medlynintercept_map = np.zeros_like(dominant_pft, dtype=np.float32)
rholnir_map = np.zeros_like(dominant_pft, dtype=np.float32)
rholvis_map = np.zeros_like(dominant_pft, dtype=np.float32)
taulnir_map = np.zeros_like(dominant_pft, dtype=np.float32)
taulvis_map = np.zeros_like(dominant_pft, dtype=np.float32)
tausnir_map = np.zeros_like(dominant_pft, dtype=np.float32)
tausvis_map = np.zeros_like(dominant_pft, dtype=np.float32)
vcmx25_map = np.zeros_like(dominant_pft, dtype=np.float32)

# Map the parameter values to the grid points based on the dominant PFT
for i in range(dominant_pft.shape[0]):
    for j in range(dominant_pft.shape[1]):
        pft_index = dominant_pft[i, j]  # PFTs are directly indexed
        if pft_index >= 0:
            medlynslope_map[i, j] = medlynslope_values[pft_index]
            medlynintercept_map[i, j] = medlynintercept_values[pft_index]
            rholnir_map[i,j]= rholnir_values[pft_index]
            rholvis_map[i,j]= rholvis_values[pft_index]
            taulnir_map[i, j] = taulnir_values[pft_index]
            taulvis_map[i, j] = taulvis_values[pft_index]
            tausnir_map[i, j] = tausnir_values[pft_index]
            tausvis_map[i, j] = tausvis_values[pft_index]
            vcmx25_map[i, j] = vcmx25_values[pft_index]

# Create a new NetCDF file with the mapped variables
with nc.Dataset(output_file, 'w', format='NETCDF4') as output_dataset:
    # Define dimensions
    output_dataset.createDimension('lat', lat.shape[0])
    output_dataset.createDimension('lon', lon.shape[1])

    # Create variables
    latitudes = output_dataset.createVariable('lat', 'f4', ('lat',))
    longitudes = output_dataset.createVariable('lon', 'f4', ('lon',))
    medlynslope_var = output_dataset.createVariable('medlynslope', 'f4', ('lat', 'lon',), fill_value=np.nan)
    medlynintercept_var = output_dataset.createVariable('medlynintercept', 'f4', ('lat', 'lon',), fill_value=np.nan)
    rholnir_var = output_dataset.createVariable('rholnir', 'f4', ('lat', 'lon',), fill_value=np.nan)
    rholvis_var = output_dataset.createVariable('rholvis', 'f4', ('lat', 'lon',), fill_value=np.nan)
    taulnir_var = output_dataset.createVariable('taulnir', 'f4', ('lat', 'lon',), fill_value=np.nan)
    taulvis_var = output_dataset.createVariable('taulvis', 'f4', ('lat', 'lon',), fill_value=np.nan)
    tausnir_var = output_dataset.createVariable('tausnir', 'f4', ('lat', 'lon',), fill_value=np.nan)
    tausvis_var = output_dataset.createVariable('tausvis', 'f4', ('lat', 'lon',), fill_value=np.nan)
    vcmx25_var = output_dataset.createVariable('vcmx25', 'f4', ('lat', 'lon',), fill_value=np.nan)

    # Assign data to variables
    latitudes[:] = np.mean(lat, axis=1)  # Assuming LATIXY and LONGXY are 2D arrays
    longitudes[:] = np.mean(lon, axis=0)  # Averaging to get 1D lat/lon
    medlynslope_var[:, :] = medlynslope_map
    medlynintercept_var[:, :] = medlynintercept_map
    rholnir_var[:, :] = rholnir_map
    rholvis_var[:, :] = rholvis_map
    taulnir_var[:, :] = taulnir_map
    taulvis_var[:, :] = taulvis_map
    tausnir_var[:, :] = tausnir_map
    tausvis_var[:, :] = tausvis_map
    vcmx25_var[:, :] = vcmx25_map

    # Assign attributes
    latitudes.units = 'degrees_north'
    longitudes.units = 'degrees_east'
    medlynslope_var.units = 'kPa^0.5'
    medlynslope_var.long_name = 'Medlyn slope of conductance-photosynthesis relationship'
    medlynintercept_var.units = 'umol m^-2 s^-1'
    medlynintercept_var.long_name = 'Medlyn intercept of conductance-photosynthesis relationship'
    rholnir_var.units ='fraction'
    rholvis_var.long_name = "Leaf reflectance: near-IR"
    rholvis_var.units ='fraction'
    rholnir_var.long_name = "Leaf reflectance: visible"
    taulnir_var.units = 'fraction'
    taulnir_var.long_name = 'Leaf transmittance: near-IR'
    taulvis_var.units = 'fraction'
    taulvis_var.long_name = 'Leaf transmittance: visible'
    tausnir_var.units = 'fraction'
    tausnir_var.long_name = 'Stem transmittance: near-IR'
    tausvis_var.units = 'fraction'
    tausvis_var.long_name = 'Stem transmittance: visible'
    vcmx25_var.units = 'umol CO2/m**2/s'
    vcmx25_var.long_name = 'Maximum rate of carboxylation at 25 degrees Celsius'

print(f"NetCDF file '{output_file}' created successfully.")
