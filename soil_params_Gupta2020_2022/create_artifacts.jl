# Ksat data derived by
# Gupta, S., Lehmann, P., Bonetti, S., Papritz, A., and Or, D., (2020)
# Global prediction of soil saturated hydraulic conductivity using random
# forest in a Covariate-based Geo Transfer Functions (CoGTF) framework.
# Journal of Advances in Modeling Earth Systems, 13(4), e2020MS002242.
# https://agupubs.onlinelibrary.wiley.com/doi/full/10.1029/2020MS002242

# Water retention curve parameters derived by
# Gupta, S., Papritz, A., Lehmann, P., Hengl, T., Bonetti, S., & Or, D. (2022).
# Global Mapping of Soil Water Characteristics Parameters—Fusing Curated Data with
# Machine Learning and Environmental Covariates. Remote Sensing, 14(8), 1947.

# First, navigate to https://zenodo.org/records/3935359 and https://zenodo.org/records/6348799
# and download saturated hydraulic conductivity data (former) and water retention
# parameter data (latter)
# stored in the .tif files there. There are four files per variable, corresponding to
# four different soil depths.

# Then, convert each tif file to nc using the script "transform_geotiff_to_netcdf.sh" found here.
# Note that you must supply the SRC_DIR and DEST_DIR to match your local paths.

# You will also need the executable "gdal_translate".

# The following `filedir` is missing intentionally - it must be replaced with paths to the nc files
# on your local machine.

using NCDatasets
using Statistics
using ClimaArtifactsHelper

filedir = "/resnick/groups/esm/ClimaArtifacts/artifacts/soil_params_Gupta2020_2022/raw_data_nc/"

include("utils.jl")
# Parameters specific to this data
z = [-1.0, -0.6, -0.3, 0] # depth of soil layer
nlayers = length(z)
lat_ct = 14937
lon_ct = 36000
data = Array{Union{Missing, Float32}}(missing, lon_ct, lat_ct, nlayers);

# just pick one of the files to get lat and lon values on the native (high res) grid
file= joinpath(filedir, "Global_n_vG_parameter_1Km_s60....60cm_v1.0.nc")
nc_data = NCDatasets.NCDataset(file)
native_lat = nc_data["lat"][:];
native_lon = nc_data["lon"][:];
native_resolution = 0.01
close(nc_data)
# Resolution of output
lowres_thin_factor = 100
hires_thin_factor = 10
hiresolution = 0.1
lowresolution = 1
outputdir = "soil_artifacts_$(hiresolution)"
if isdir(outputdir)
    @warn "$outputdir already exists. Content will end up in the artifact and may be overwritten."
    @warn "Abort this calculation, unless you know what you are doing."
else
    mkdir(outputdir)
end
outputdir_lowres = "soil_artifacts_$(lowresolution)"
if isdir(outputdir_lowres)
    @warn "$outputdir_lowres already exists. Content will end up in the artifact and may be overwritten."
    @warn "Abort this calculation, unless you know what you are doing."
else
    mkdir(outputdir_lowres)
end

# Function which reads in the data, thins the data, writes the file to the correct output location.
function create_artifact(data, files, attrib, transform, outfilepath; thin_factor = 1)
    thinned_data, thinned_lat, thinned_lon = thin_data(data, (native_lon, native_lat), transform, thin_factor, nlayers)
    write_nc_out(thinned_data, thinned_lat, thinned_lon, z, attrib, outfilepath)
end

# Process Ksat
files = [
    "Global_Ksat_1Km_s100....100cm_v1.0.nc",
    "Global_Ksat_1Km_s60....60cm_v1.0.nc",
    "Global_Ksat_1Km_s30....30cm_v1.0.nc",
    "Global_Ksat_1Km_s0....0cm_v1.0.nc",
]
transform(x) = 10^x / (100 * 24 * 3600) # how to convert to units the simulation needs
outfilepath = joinpath(outputdir,"ksat_map_gupta_etal2020_$(hiresolution)x$(hiresolution)x$(nlayers).nc")
outfilepath_lowres = joinpath(outputdir_lowres, "ksat_map_gupta_etal2020_$(lowresolution)x$(lowresolution)x$(nlayers).nc")
attrib = (;
    vartitle = "Saturated Hydraulic Conductivity",
    varunits = "m/s",
    varname = "Ksat",
)
# get parameter values at each layer
read_nc_data!(data, files, filedir)
@info "Creating highres Ksat artifact at $(outfilepath)"
create_artifact(data, files, attrib, transform, outfilepath; thin_factor = hires_thin_factor)
@info "Creating lowres Ksat artifact at $(outfilepath_lowres)"
create_artifact(data, files, attrib, transform, outfilepath_lowres; thin_factor = lowres_thin_factor)

# Process Porosity
files = [
    "Global_thetas_vG_parameter_1Km_s100....100cm_v1.0.nc",
    "Global_thetas_vG_parameter_1Km_s60....60cm_v1.0.nc",
    "Global_thetas_vG_parameter_1Km_s30....30cm_v1.0.nc",
    "Global_thetas_vG_parameter_1Km_s0....0cm_v1.0.nc",
]
transform(x) = x # how to convert to units the simulation needs
outfilepath = joinpath(outputdir, "porosity_map_gupta_etal2020_$(hiresolution)x$(hiresolution)x$(nlayers).nc")
outfilepath_lowres = joinpath(outputdir_lowres,"porosity_map_gupta_etal2020_$(lowresolution)x$(lowresolution)x$(nlayers).nc")
attrib = (; vartitle = "Porosity", varunits = "m^3/m^3", varname = "ν")
# get parameter values at each layer
read_nc_data!(data, files, filedir)
@info "Creating highres porosity artifact at $(outfilepath)"
create_artifact(data, files, attrib, transform, outfilepath; thin_factor = hires_thin_factor)
@info "Creating lowres porosity artifact at $(outfilepath_lowres)"
create_artifact(data, files, attrib, transform, outfilepath_lowres; thin_factor = lowres_thin_factor)

# Process Residual Water Fraction
files = [
    "Global_thetar_vG_parameter_1Km_s100....100cm_v1.0.nc",
    "Global_thetar_vG_parameter_1Km_s60....60cm_v1.0.nc",
    "Global_thetar_vG_parameter_1Km_s30....30cm_v1.0.nc",
    "Global_thetar_vG_parameter_1Km_s0....0cm_v1.0.nc",
]
transform(x) = x # how to convert to units the simulation needs
outfilepath = joinpath(outputdir,"residual_map_gupta_etal2020_$(hiresolution)x$(hiresolution)x$(nlayers).nc")
outfilepath_lowres = joinpath(outputdir_lowres, "residual_map_gupta_etal2020_$(lowresolution)x$(lowresolution)x$(nlayers).nc")
attrib = (;
    vartitle = "Residual water fraction",
    varunits = "m^3/m^3",
    varname = "θ_r",
)
# get parameter values at each layer
read_nc_data!(data, files, filedir)
@info "Creating highres residual water fraction artifact at $(outfilepath)"
create_artifact(data, files, attrib, transform, outfilepath; thin_factor = hires_thin_factor)
@info "Creating lowres residual water fraction artifact at $(outfilepath_lowres)"
create_artifact(data, files, attrib, transform, outfilepath_lowres; thin_factor = lowres_thin_factor)

# Process van Genuchten alpha
files = [
    "Global_alpha_vG_parameter_1Km_s100....100cm_v1.0.nc",
    "Global_alpha_vG_parameter_1Km_s60....60cm_v1.0.nc",
    "Global_alpha_vG_parameter_1Km_s30....30cm_v1.0.nc",
    "Global_alpha_vG_parameter_1Km_s0....0cm_v1.0.nc",
]
transform(x) = 10^x# how to convert to units the simulation needs
outfilepath = joinpath(outputdir, "vGalpha_map_gupta_etal2020_$(hiresolution)x$(hiresolution)x$(nlayers).nc")
outfilepath_lowres = joinpath(outputdir_lowres,"vGalpha_map_gupta_etal2020_$(lowresolution)x$(lowresolution)x$(nlayers).nc")
attrib = (; vartitle = "van Genuchten α", varunits = "1/m", varname = "α")
# get parameter values at each layer
read_nc_data!(data, files, filedir)
@info "Creating highres van Genuchten alpha artifact at $(outfilepath)"
create_artifact(data, files, attrib, transform, outfilepath; thin_factor = hires_thin_factor)
@info "Creating lowres van Genuchten alpha artifact at $(outfilepath_lowres)"
create_artifact(data, files, attrib, transform, outfilepath_lowres; thin_factor = lowres_thin_factor)

# Process van Genuchten n
files = [
    "Global_n_vG_parameter_1Km_s100....100cm_v1.0.nc",
    "Global_n_vG_parameter_1Km_s60....60cm_v1.0.nc",
    "Global_n_vG_parameter_1Km_s30....30cm_v1.0.nc",
    "Global_n_vG_parameter_1Km_s0....0cm_v1.0.nc",
]
transform(x) = 10^x # how to convert to units the simulation needs
outfilepath = joinpath(outputdir, "vGn_map_gupta_etal2020_$(hiresolution)x$(hiresolution)x$(nlayers).nc")
outfilepath_lowres = joinpath(outputdir_lowres, "vGn_map_gupta_etal2020_$(lowresolution)x$(lowresolution)x$(nlayers).nc")
attrib = (; vartitle = "van Genuchten n", varunits = "unitless", varname = "n")
# get parameter values at each layer
read_nc_data!(data, files, filedir)
@info "Creating highres van Genuchten n artifact at $(outfilepath)"
create_artifact(data, files, attrib, transform, outfilepath; thin_factor= hires_thin_factor)
@info "Creating lowres van Genuchten n artifact at $(outfilepath_lowres)"
create_artifact(data, files, attrib, transform, outfilepath_lowres; thin_factor = lowres_thin_factor)

create_artifact_guided(outputdir; artifact_name = basename(@__DIR__))
create_artifact_guided(outputdir_lowres; artifact_name = basename(@__DIR__) * "_lowres", append = true)
