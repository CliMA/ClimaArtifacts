# First, we combine the different files with different soil layer parameters
# into a single file per parameter. We also transform the variables into
# standard SI units (kg, m).
z = [-1.5, -0.8, -0.45, -0.225, -0.1, -0.025] # depth of soil layer
nlayers = length(z)
level_names = ["100-200cm","60-100cm","30-60cm","15-30cm","5-15cm","0-5cm"]
vars = ["bdod","silt","sand","clay","cfvo","soc"]
nvars = length(vars)

# Attributes and unit transformations for each variable
attrib_bdod = (;
    vartitle = "Dry bulk density of fine earth fraction",
    varunits = "kg/m^3",
    varname = "bdod",
)
transform_bdod(x) = x*1e-5*1e6 # how to convert to from cg/cm^3 to kg/m^3
attrib_silt = (;
    vartitle = "Mass fraction of silt in the mineral part of the fine earth fraction of soil",
    varunits = "kg/kg",
    varname = "f_silt")
attrib_sand = (;
    vartitle = "Mass fraction of sand in the mineral part of the fine earth fraction of soil",
    varunits = "kg/kg",
    varname = "f_sand")
attrib_clay = (;
    vartitle = "Mass fraction of clay in the mineral part of the fine earth fraction of soil",
    varunits = "kg/kg",
    varname = "f_clay")
transform_comp(x) = x*1e-3 # how to convert to from g/kg to kg/kg
attrib_cfvo = (;
    vartitle = "Volumetric fraction of coarse fragments",
    varunits = "m^3/m^3",
    varname = "cfvo")
transform_cfvo(x) = x*1e-3 # how to convert to from (cm/dm)^3 to (m/m)^3
attrib_soc = (;
    vartitle = "Mass fraction of soil organic carbon in the fine earth fraction of soil",
    varunits = "kg/kg",
    varname = "q_soc")
transform_soc(x) = x * 1e-4 # how to convert to from dg/kg to kg/kg

attribs = [attrib_bdod, attrib_silt, attrib_sand, attrib_clay, attrib_cfvo, attrib_soc]
transforms = [transform_bdod, transform_comp, transform_comp, transform_comp, transform_cfvo, transform_soc]


# Open one file to get the lat/lon dimensionality, and allocate
# memory for a parameter of size nlon x nlat x nlayers.
# Pre-allocation speeds up the code.

file= joinpath(filedir, "bdod_0-5cm_mean_5000.nc")
nc_data = NCDatasets.NCDataset(file)
lat = nc_data["lat"][:];
lon = nc_data["lon"][:];
nlat = length(lat)
nlon = length(lon)

data = Array{Union{Missing, Float32}}(missing, nlon, nlat, nlayers); # nlayers defined in "combine_and_transform_raw_data.jl"

# Function which reads in the data by layer and writes the file with all layers to the correct output location.
function create_combined_data!(data, files, attrib, transform, outfilepath)
    # get parameter values at each layer
    read_nc_data!(data, files, filedir)
    # Replace missing with 0
    data[typeof.(data) .== Missing] .= Float32(NaN)
    data .= transform(data)
    write_nc_out(data, lat, lon, z, attrib, outfilepath)
end
