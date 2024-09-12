using NCDatasets
using Statistics
using ClimaArtifactsHelper

if length(ARGS) < 1
    @error("Please provide the local path to raw nc data directory.")
else
    filedir = ARGS[1]
end
tmpdir = "soilgrids_tmp"
outputdir = "soilgrids"
outputdir_lowres = "soilgrids_lowres"
for dir in [tmpdir, outputdir, outputdir_lowres]
    if isdir(dir)
        @warn "$dir already exists. Content will end up in the artifact and may be overwritten."
	    @warn "Abort this calculation, unless you know what you are doing."
    else
	mkdir(dir)
    end
end

include("utils.jl")
# First, we combine the different files with different soil layer parameters
# into a single file per parameter. We also transform the variables into
# standard SI units (kg, m), and save each parameter to a netcdf file
# with given atttributes.

include("combine_and_transform_raw_data.jl")
# Here, nvars, vars, attribs, transforms, level_names, and the pre-allocated
# memory `data` were created in "combine_and_transform_raw_data.jl", along
# with the function `create_combined_data`.
for i in 1:nvars
    var = vars[i]
    attrib = attribs[i]
    transform = transforms[i]
    files = ["$(var)_$(ln)_mean_5000.nc" for ln in level_names]
    outfilepath = joinpath(tmpdir, "$(var)_soilgrids_combined.nc")
    create_combined_data!(data, files, attrib, transform, outfilepath)
end

# Next, we read in the transformed SoilGrids data (nlon x nlat x nlayers)
# that we created and combine them to create the variables we actually
# need in the ClimaLand model

# Some notes on the variables:
# cf = coarse fragments - particles > 2mm
# fe = fine earth - particles < 2mm, this includes SOC and empty pores
# soc = organic matter
# min = silt, clay, sand

# - q_i = mass of i/mass of fine earth
# - f_i = mass of i/mass of minerals in fine earth
# - θ_i = volumetric fraction of soil component relative to whole soil
# - q_soc + q_min = 1 (fine earth mass fractions)
# - f_i * (1-q_soc) = q_i (fine earth mass fraction of mineral i)
# - f_silt .+ f_sand .+ f_clay = 1; # sums to 1 in the data
# - θ_fe + θ_cf = 1, porosity included in θ_fe
# - ν_fe = volume of pores in fine earth/volume of fine earth
# - ν = volume of pore/volume of whole soil
# - ν_ss_i = volume of soil solid relative to soil solids (incudes fine and coarse soil components)

# Particle density
ρp_min = Float32(2.7*1e3)
ρp_soc = Float32(1.3*1e3)
ρp_cf = ρp_min

# Fine earth
soc = NCDataset(joinpath(tmpdir, "soc_soilgrids_combined.nc"));
q_soc = soc["q_soc"][:,:,:];
silt = NCDataset(joinpath(tmpdir, "silt_soilgrids_combined.nc"));
q_silt = silt["f_silt"][:,:,:] .* (1 .- q_soc);
clay = NCDataset(joinpath(tmpdir, "clay_soilgrids_combined.nc"));
q_clay = clay["f_clay"][:,:,:].* (1 .- q_soc);
sand = NCDataset(joinpath(tmpdir, "sand_soilgrids_combined.nc"));
q_sand = sand["f_sand"][:,:,:].* (1 .- q_soc);

fe_density = NCDataset(joinpath(tmpdir, "bdod_soilgrids_combined.nc"));
ρ_bulk_fe = fe_density["bdod"][:,:,:]; # Mass of fine earth/ Volume of fine earth including pores

# Whole soil 
cf = NCDataset(joinpath(tmpdir, "cfvo_soilgrids_combined.nc"));
θ_cf = cf["cfvo"][:,:,:]; # volume of gravel/volume of whole soil

function compute_θ_i(q_i, ρp_i, q_soc, q_silt, q_clay, q_sand, ρ_bulk_fe, θ_cf)
    q_min = q_silt + q_sand + q_clay
    ρp_fe =  1/(q_soc/ρp_soc + q_min/ρp_min);
    ν_fe =  1-ρ_bulk_fe/ρp_fe;
    θ_fe = 1 - θ_cf; # pore space already accounted for in θ_fe
    θ_i =  q_i / ρp_i * ρ_bulk_fe * θ_fe;
    return θ_i
end

function compute_ν(q_soc, q_silt, q_clay, q_sand, ρ_bulk_fe, θ_cf)
    q_min = q_silt + q_sand + q_clay
    ρp_fe =  1/(q_soc/ρp_soc + q_min/ρp_min);
    ν_fe =  1-ρ_bulk_fe/ρp_fe;
    θ_fe = 1 - θ_cf; # pore space already accounted for in θ_fe
    ν =  ν_fe * θ_fe;
    return ν
end
θ_sand = compute_θ_i.(q_sand, ρp_min, q_soc, q_silt, q_clay, q_sand, ρ_bulk_fe, θ_cf);
θ_soc = compute_θ_i.(q_soc, ρp_soc, q_soc, q_silt, q_clay, q_sand, ρ_bulk_fe, θ_cf);
ν = compute_ν.(q_soc, q_silt, q_clay, q_sand, ρ_bulk_fe, θ_cf);
ν_ss_soc =  @. θ_soc/(1-ν);
ν_ss_cf =  @. θ_cf/(1-ν);
ν_ss_sand = @.  θ_sand / (1-ν);

# Sanity checks
#=
check_extrema(x) = extrema(x[ .! isnan.(x)])
function percentiles(x)
    y = x[ .! isnan.(x)]
    return (median(y), mean(y), quantile(y, 0.01), quantile(y,0.99))
end
sum_f = silt["f_silt"][:,:,1] .+ clay["f_clay"][:,:,1] .+ sand["f_sand"][:,:,1];
sum_q = @. q_soc + q_silt + q_clay + q_sand;
check_extrema(sum_f) # 1
check_extrema(sum_q) # 1
percentiles(ν) # reasonable
check_extrema(ν_ss_soc .+ ν_ss_cf .+ ν_ss_sand) # lies between 0 and 1!
=#

# Save these as our output data
attrib_ν_ss_soc = (;
                   vartitle = "Volumetric fraction of organic matter relative to soil solids",
                   varunits = "m^3/m^3",
                   varname = "nu_ss_om",
                   )
attrib_ν_ss_sand = (;
                   vartitle = "Volumetric fraction of quartz/sand relative to soil solids",
                   varunits = "m^3/m^3",
                   varname = "nu_ss_sand",
                   )
attrib_ν_ss_cf = (;
                   vartitle = "Volumetric fraction of coarse fragments relative to soil solids",
                   varunits = "m^3/m^3",
                   varname = "nu_ss_cf",
                  )
# We still need to handle missing data, which appears as NaN
replace_nan_with_zero(x) = isnan(x) ? typeof(x)(0) : x

# Full data at high resolution
outfilepath = joinpath(outputdir, "soil_solid_vol_fractions_soilgrids.nc")
ds = NCDataset(outfilepath, "c")
# Define and set values for dimensions (lon, lat, z)
defDim(ds, "lon", nlon)
defDim(ds, "lat", nlat)
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
la[:] = lat
lo[:] = lon
zv[:] = z
# Define our variables
for (vardata, attrib) in [(ν_ss_soc, attrib_ν_ss_soc), (ν_ss_sand, attrib_ν_ss_sand), (ν_ss_cf, attrib_ν_ss_cf), ]
    (vartitle, varunits, varname) = attrib
    var = defVar(ds, varname, Float32, ("lon", "lat", "z"))
    var.attrib["units"] = varunits
    var.attrib["longname"]= vartitle
    var.attrib["varname"] = varname
    var[:, :, :] = replace_nan_with_zero.(vardata)
end
close(ds)


# Full data at ~1 degree resolution
outfilepath = joinpath(outputdir_lowres, "soil_solid_vol_fractions_soilgrids_lowres.nc")
ds = NCDataset(outfilepath, "c")
# Define and set values for dimensions (lon, lat, z)
lon_indices = range(stop = length(lon), start = 1, step = 22)
lat_indices = range(stop = length(lat), start = 1, step = 17)
defDim(ds, "lon", length(lon_indices))
defDim(ds, "lat", length(lat_indices))
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
la[:] = lat[lat_indices]
lo[:] = lon[lon_indices]
zv[:] = z
# Define our variables
for (vardata, attrib) in [(ν_ss_soc, attrib_ν_ss_soc), (ν_ss_sand, attrib_ν_ss_sand), (ν_ss_cf, attrib_ν_ss_cf), ]
    (vartitle, varunits, varname) = attrib
    var = defVar(ds, varname, Float32, ("lon", "lat", "z"))
    var.attrib["units"] = varunits
    var.attrib["longname"]= vartitle
    var.attrib["varname"] = varname
    var[:, :, :] = replace_nan_with_zero.(vardata[lon_indices, lat_indices, :])
end
close(ds)


create_artifact_guided(outputdir_lowres; artifact_name = basename(@__DIR__)* "_lowres", append = true)
