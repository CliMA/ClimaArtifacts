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

# The following `filedir` is missing intentionally - it must be replaced with paths to the tif files
# on your local machine.

using TiffImages
using NCDatasets
using Statistics
using ClimaArtifactsHelper

filedir = missing

outputdir = "soil_artifacts"
if isdir(outputdir)
    @warn "$outputdir already exists. Content will end up in the artifact and may be overwritten."
    @warn "Abort this calculation, unless you know what you are doing."
else
    mkdir(outputdir)
end

include("utils.jl")
# Parameters specific to this data
z = [-1.0, -0.6, -0.3, 0] # depth of soil layer
nlayers = length(z)
lat_ct = 14937
lon_ct = 36000
lon_edges = range(-180.0, 180.0, length = lon_ct + 1)
lon = Array(0.5 * (lon_edges[1:(end - 1)] .+ lon_edges[2:end]))
lat_edges = range(-62.0, 87.37, length = lat_ct + 1) # From S. Gupta, via email.
lat = Array(0.5 * (lat_edges[1:(end - 1)] .+ lat_edges[2:end]))
data = zeros(Float32, lon_ct, lat_ct, nlayers);

# Simulation Resolution
resolution = 2.5

# Function which reads in the data, regrids to the simulation grid, writes the file to the correct output location.
function create_artifact(data, files, attrib, transform, outfilepath)
    read_tif_data!(data, files, filedir)
    outdata, outlat, outlon =
        regrid(data, (lon, lat), resolution, transform, nlayers)
    write_nc_out(outdata, outlat, outlon, z, attrib, outfilepath)
    Base.mv(outfilepath, joinpath(outputdir, outfilepath))
end

# Process Ksat
files = [
    "Global_Ksat_1Km_s100....100cm_v1.0.tif",
    "Global_Ksat_1Km_s60....60cm_v1.0.tif",
    "Global_Ksat_1Km_s30....30cm_v1.0.tif",
    "Global_Ksat_1Km_s0....0cm_v1.0.tif",
]
transform(x) = 10^x / (100 * 24 * 3600) # how to convert to units the simulation needs
outfilepath = "ksat_map_gupta_etal2020_$(resolution)x$(resolution)x$(nlayers).nc"
attrib = (;
    vartitle = "Saturated Hydraulic Conductivity",
    varunits = "m/s",
    varname = "Ksat",
)
create_artifact(data, files, attrib, transform, outfilepath)

# Process Porosity
files = [
    "Global_thetas_vG_parameter_1Km_s100....100cm_v1.0.tif",
    "Global_thetas_vG_parameter_1Km_s60....60cm_v1.0.tif",
    "Global_thetas_vG_parameter_1Km_s30....30cm_v1.0.tif",
    "Global_thetas_vG_parameter_1Km_s0....0cm_v1.0.tif",
]
transform(x) = x # how to convert to units the simulation needs
outfilepath = "porosity_map_gupta_etal2020_$(resolution)x$(resolution)x$(nlayers).nc"
attrib = (; vartitle = "Porosity", varunits = "m^3/m^3", varname = "ν")
create_artifact(data, files, attrib, transform, outfilepath)

# Process Residual Water Fraction
files = [
    "Global_thetar_vG_parameter_1Km_s100....100cm_v1.0.tif",
    "Global_thetar_vG_parameter_1Km_s60....60cm_v1.0.tif",
    "Global_thetar_vG_parameter_1Km_s30....30cm_v1.0.tif",
    "Global_thetar_vG_parameter_1Km_s0....0cm_v1.0.tif",
]
transform(x) = x # how to convert to units the simulation needs
outfilepath = "residual_map_gupta_etal2020_$(resolution)x$(resolution)x$(nlayers).nc"
attrib = (;
    vartitle = "Residual water fraction",
    varunits = "m^3/m^3",
    varname = "θ_r",
)
create_artifact(data, files, attrib, transform, outfilepath)

# Process van Genuchten alpha
files = [
    "Global_alpha_vG_parameter_1Km_s100....100cm_v1.0.tif",
    "Global_alpha_vG_parameter_1Km_s60....60cm_v1.0.tif",
    "Global_alpha_vG_parameter_1Km_s30....30cm_v1.0.tif",
    "Global_alpha_vG_parameter_1Km_s0....0cm_v1.0.tif",
]
transform(x) = 10^x# how to convert to units the simulation needs
outfilepath = "vGalpha_map_gupta_etal2020_$(resolution)x$(resolution)x$(nlayers).nc"
attrib = (; vartitle = "van Genuchten α", varunits = "1/m", varname = "α")
create_artifact(data, files, attrib, transform, outfilepath)

# Process van Genuchten n
files = [
    "Global_n_vG_parameter_1Km_s100....100cm_v1.0.tif",
    "Global_n_vG_parameter_1Km_s60....60cm_v1.0.tif",
    "Global_n_vG_parameter_1Km_s30....30cm_v1.0.tif",
    "Global_n_vG_parameter_1Km_s0....0cm_v1.0.tif",
]
transform(x) = 10^x # how to convert to units the simulation needs
outfilepath = "vGn_map_gupta_etal2020_$(resolution)x$(resolution)x$(nlayers).nc"
attrib = (; vartitle = "van Genuchten n", varunits = "unitless", varname = "n")
create_artifact(data, files, attrib, transform, outfilepath)

create_artifact_guided(outputdir; artifact_name = basename(@__DIR__))
