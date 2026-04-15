# Combine the per-layer OCD files into a single file and convert units to SI.
#
# SoilGrids stores OCD (organic carbon density) as integers in units of hg/m³
# (hectograms per cubic metre). Conversion to kg/m³: multiply by 0.1.
# Verify against https://www.isric.org/explore/soilgrids/faq-soilgrids if in doubt.

z = [-1.5, -0.8, -0.45, -0.225, -0.1, -0.025] # depth of soil layer midpoints (m)
nlayers = length(z)
level_names = ["100-200cm","60-100cm","30-60cm","15-30cm","5-15cm","0-5cm"]

attrib_ocd = (;
    vartitle = "Soil organic carbon density",
    varunits = "kg/m^3",
    varname = "ocd",
)
transform_ocd(x) = x * 0.1  # hg/m³ -> kg/m³

# Open one file to get lat/lon dimensionality and pre-allocate memory
file = joinpath(filedir, "ocd_0-5cm_mean_5000.nc")
nc_data = NCDatasets.NCDataset(file)
lat = nc_data["lat"][:]
lon = nc_data["lon"][:]
nlat = length(lat)
nlon = length(lon)

data = Array{Union{Missing, Float32}}(missing, nlon, nlat, nlayers)

function create_combined_data!(data, files, attrib, transform, outfilepath)
    read_nc_data!(data, files, filedir)
    data[typeof.(data) .== Missing] .= Float32(NaN)
    data .= transform(data)
    write_nc_out(data, lat, lon, z, attrib, outfilepath)
end
