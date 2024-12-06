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
)

function create_cloud(variables, outfile_path; small=false)

    ncout = NCDataset(outfile_path, "c")
    infile_path = map(a -> "era5_cloud_hourly_"*variables[1]*"_2010"*lpad(string(a),2,"0")*".nc", collect(1:2))
    ncin = NCDataset(infile_path, aggdim = "valid_time")
    
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
        infile_path = map(a -> "era5_cloud_hourly_"*variable*"_2010"*lpad(string(a),2,"0")*".nc", collect(1:2))
        ncin = NCDataset(infile_path, aggdim = "valid_time")
        name = short_name_dict[variable]
        attribs = Dict([
            attrib_rename => ncin[name].attrib[attrib_name] for
            (attrib_name, attrib_rename) in zip(attrib_names, attrib_renames)
        ])
        defVar(
            ncout,
            name,
            FT,
            ("lon", "lat", "z", "time"),
            attrib = attribs,
        )
        ncout[name][:,:,:,:] = reverse(ncin[name][begin:THINNING_FACTOR:end,begin:THINNING_FACTOR:end,:,begin:THINNING_FACTOR:end], dims=2)
        close(ncin)
    end

    close(ncout)
end

output_dir = "era5_cloud_hourly_artifact"

if isdir(output_dir)
    @warn "$output_dir already exists. Content will end up in the artifact and may be overwritten."
    @warn "Abort this calculation, unless you know what you are doing."
else
    mkdir(output_dir)
end

variables = ["fraction_of_cloud_cover", "specific_cloud_liquid_water_content"]
create_cloud(variables, joinpath(output_dir, "era5_cloud_hourly_lowres.nc"); small=true)

#@info "Data file generated!"
#create_artifact_guided(output_dir; artifact_name = basename(@__DIR__))
