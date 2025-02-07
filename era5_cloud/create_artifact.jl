using NCDatasets
using ClimaArtifactsHelper

const H_EARTH = 7000.0
const P0 = 1e5
const HPA_TO_PA = 100.0

Plvl_inv(P) = -H_EARTH * log(P / P0)

short_name_dict = Dict(
    "fraction_of_cloud_cover" => "cc",
    "specific_cloud_liquid_water_content" => "clwc",
    "specific_cloud_ice_water_content" => "ciwc",
    "specific_humidity" => "q",
    "relative_humidity" => "r",
)

function create_cloud(variables, outfile_path; small=false)

    ncout = NCDataset(outfile_path, "c")
    infile_paths = map(m -> "era5_cloud_hourly_$(variables[1])_2010$(m).nc", lpad.(1:12, 2, "0"))
    length(infile_paths) != 12 && error(
        "Did not find twelve .nc files for variable $(variables[1]). Rerun Python script or check that all files are downloaded in this directory.",
    )
    ncin = NCDataset(infile_paths, aggdim = "valid_time")
    
    FT = Float32
    THINNING_FACTOR = small ? 6 : 1

    defDim(ncout, "lon", Int(ceil(length(ncin["longitude"]) // THINNING_FACTOR)))
    defDim(ncout, "lat", Int(ceil(length(ncin["latitude"]) // THINNING_FACTOR)))
    defDim(ncout, "z", length(ncin["pressure_level"]))
    defDim(ncout, "time", Int(ceil(length(ncin["valid_time"]) // THINNING_FACTOR)))

    lon_attribs = Dict(ncin["longitude"].attrib)
    lon_attribs["_FillValue"] = NaN32
    lon = defVar(ncout, "lon", FT, ("lon",), attrib = lon_attribs)
    lon[:] = Array(ncin["longitude"])[begin:THINNING_FACTOR:end]

    lat_attribs = Dict(ncin["latitude"].attrib)
    lat_attribs["_FillValue"] = NaN32
    lat = defVar(ncout, "lat", FT, ("lat",), attrib = lat_attribs)
    # ERA5 latitude coordinate is from 90 to -90, here we reverse it so that we can use ClimaUtilitiles.
    lat[:] = reverse(Array(ncin["latitude"])[begin:THINNING_FACTOR:end])

    z = defVar(ncout, "z", FT, ("z",))
    plevin = ncin["pressure_level"] .* HPA_TO_PA
    @. z = Plvl_inv(plevin)
    z.attrib["long_name"] = "altitude"
    z.attrib["units"] = "meters"

    time_ = defVar(
        ncout,
        "time",
        Int32,
        ("time",),
        attrib = ncin["valid_time"].attrib,
    )
    time_[:] = Array(ncin["valid_time"])[begin:THINNING_FACTOR:end]
    close(ncin)

    attrib_names =
        ["standard_name", "long_name", "units", "_FillValue", "GRIB_missingValue"]
    attrib_renames = ["standard_name", "long_name", "units", "_FillValue", "missing_value"]
    for variable in variables
        infile_paths = map(m -> "era5_cloud_hourly_$(variable)_2010$(m).nc", lpad.(1:12, 2, "0"))
        length(infile_paths) != 12 && error(
            "Did not find twelve .nc files for variable $(variable). Rerun Python script or check that all files are downloaded in this directory.",
        )
        ncin = NCDataset(infile_paths, aggdim = "valid_time")
        name = short_name_dict[variable]
        attribs = Dict([
            attrib_rename => ncin[name].attrib[attrib_name] for
            (attrib_name, attrib_rename) in zip(attrib_names, attrib_renames)
        ])
        # change relative humidity to ratio from percent
        attribs["units"] = variable == "relative_humidity" ? "" : attribs["units"]
        defVar(
            ncout,
            name,
            FT,
            ("lon", "lat", "z", "time"),
            attrib = attribs,
        )
        ncout[name][:,:,:,:] = reverse(ncin[name][begin:THINNING_FACTOR:end,begin:THINNING_FACTOR:end,:,begin:THINNING_FACTOR:end], dims=2)
        if variable == "relative_humidity"
            ncout[name][:,:,:,:] = clamp.(ncout[name][:,:,:,:], FT(0), FT(100)) / FT(100)
        end
        close(ncin)
    end

    close(ncout)
end

variables = [
    "fraction_of_cloud_cover",
    "specific_cloud_liquid_water_content",
    "specific_cloud_ice_water_content",
    "specific_humidity",
    "relative_humidity",
]

output_dir = "era5_cloud_artifact"
if isdir(output_dir)
    @warn "$output_dir already exists. Content will end up in the artifact and may be overwritten."
    @warn "Abort this calculation, unless you know what you are doing."
else
    mkdir(output_dir)
end

create_cloud(variables, joinpath(output_dir, "era5_cloud.nc"))

@info "Data file generated!"
create_artifact_guided(output_dir; artifact_name = basename(@__DIR__))

output_dir_lowres = "era5_cloud_artifact_lowres"
if isdir(output_dir_lowres)
    @warn "$output_dir_lowres already exists. Content will end up in the artifact and may be overwritten."
    @warn "Abort this calculation, unless you know what you are doing."
else
    mkdir(output_dir_lowres)
end

create_cloud(variables, joinpath(output_dir_lowres, "era5_cloud_lowres.nc"), small=true)

@info "Data file generated!"
create_artifact_guided(output_dir_lowres; artifact_name = basename(@__DIR__) * "_lowres", append=true)
