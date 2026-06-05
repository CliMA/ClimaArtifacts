using NCDatasets
using Statistics
using ClimaArtifactsHelper

if length(ARGS) < 1
    @error("Please provide the local path to raw nc data directory.")
else
    filedir = ARGS[1]
end

# just pick one of the files to get lat and lon values on the native (high res) grid
file= joinpath(filedir, "Hydraul_Param_SoilGrids_Schaap_sl1.nc")
nc_data = NCDatasets.NCDataset(file)
native_lat = nc_data["latitude"][:];
native_lon = nc_data["longitude"][:];
close(nc_data)
# Parameters specific to this data
native_z = [-2.0, -1.0, -0.6, -0.3, -0.15, -0.05, 0] # depth of soil layer
nlayers = length(native_z)
lat_ct = length(native_lat)
lon_ct = length(native_lon)
data = Array{Union{Missing, Float32}}(missing, lon_ct, lat_ct, nlayers, 5);

outputdir = "soil_params_rosetta"
if isdir(outputdir)
    @warn "$outputdir already exists. Content will end up in the artifact and may be overwritten."
    @warn "Abort this calculation, unless you know what you are doing."
else
    mkdir(outputdir)
end

files = ["Hydraul_Param_SoilGrids_Schaap_sl1.nc",
         "Hydraul_Param_SoilGrids_Schaap_sl2.nc",
         "Hydraul_Param_SoilGrids_Schaap_sl3.nc",
         "Hydraul_Param_SoilGrids_Schaap_sl4.nc",
         "Hydraul_Param_SoilGrids_Schaap_sl5.nc",
         "Hydraul_Param_SoilGrids_Schaap_sl6.nc",
         "Hydraul_Param_SoilGrids_Schaap_sl7.nc"]
transform_ksat(x) = ismissing(x)  ? 0f0 : x / (100 * 24 * 3600) # cm/day -> m/s
no_transform(x) = ismissing(x)  ? 0f0 : x
transform_alpha(x) = ismissing(x)  ? 0f0 : x*100 # 1/cm -> 1/m
levels = ["0cm", "5cm", "15cm", "30cm", "60cm", "100cm", "200cm" ]
for i in 1:7
    file= joinpath(filedir, files[i])
    nc_data = NCDatasets.NCDataset(file)
    level = levels[i]
    data[:,:,i, 1] .= transform_ksat.(nc_data["mean_Ks_$level"][:,:])
    data[:,:,i, 2] .= transform_alpha.(nc_data["alpha_fit_$level"][:,:])
    data[:,:,i, 3] .= no_transform.(nc_data["n_fit_$level"][:,:])
    data[:,:,i, 4] .= no_transform.(nc_data["mean_theta_s_$level"][:,:])
    data[:,:,i, 5] .= no_transform.(nc_data["mean_theta_r_$level"][:,:])
    close(nc_data)
end

attrib_ksat = (;
    vartitle = "Saturated Hydraulic Conductivity",
    varunits = "m/s",
    varname = "Ksat",
)

attrib_theta_r = (;
    vartitle = "Residual water fraction",
    varunits = "m^3/m^3",
    varname = "θ_r",
)
attrib_theta_s = (;
    vartitle = "Saturated water fraction",
    varunits = "m^3/m^3",
    varname = "ν",
)
attrib_α = (; vartitle = "van Genuchten α", varunits = "1/m", varname = "α")
attrib_n = (; vartitle = "van Genuchten n", varunits = "unitless", varname = "n")
ds = NCDataset("soil_params_rosetta.nc", "c")
defDim(ds, "lon", lon_ct)
defDim(ds, "lat", lat_ct)
defDim(ds, "z", nlayers)
la = defVar(ds, "lat", Float32, ("lat",))
lo = defVar(ds, "lon", Float32, ("lon",))
zv = defVar(ds, "z", Float32, ("z",))
la.attrib["units"] = "degrees_north"
la.attrib["standard_name"] = "latitude"
lo.attrib["standard_name"] = "longitude"
lo.attrib["units"] = "degrees_east"
zv.attrib["standard_name"] = "depth"
zv.attrib["units"] = "m"
la[:] = native_lat
lo[:] = native_lon
zv[:] = native_z

var1 = defVar(ds, "Ksat", Float32, ("lon", "lat", "z"))
var1.attrib["units"] = attrib_ksat.varunits
var1.attrib["title"] = attrib_ksat.vartitle
var1[:, :, :] .= data[:,:,:,1]

var2 = defVar(ds, "vg_α", Float32, ("lon", "lat", "z"))
var2.attrib["units"] = attrib_α.varunits
var2.attrib["title"] = attrib_α.vartitle
var2[:, :, :] .= data[:,:,:,2]

var3 = defVar(ds, "vg_n", Float32, ("lon", "lat", "z"))
var3.attrib["units"] = attrib_n.varunits
var3.attrib["title"] = attrib_n.vartitle
var3[:, :, :] .= data[:,:,:,3]

var4 = defVar(ds, "ν", Float32, ("lon", "lat", "z"))
var4.attrib["units"] = attrib_theta_s.varunits
var4.attrib["title"] = attrib_theta_s.vartitle
var4[:, :, :] .= data[:,:,:,4]

var5 = defVar(ds, "θ_r", Float32, ("lon", "lat", "z"))
var5.attrib["units"] = attrib_theta_r.varunits
var5.attrib["title"] = attrib_theta_r.vartitle
var5[:, :, :] .= data[:,:,:,5]
close(ds)
create_artifact_guided(outputdir; artifact_name = basename(@__DIR__))
