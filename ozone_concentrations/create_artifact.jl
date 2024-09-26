using Dates
using Downloads
using NCDatasets

using ClimaArtifactsHelper

FILE_URLs = [
    "https://caltech.box.com/shared/static/hj2yucye0u3l8e4x8o1d0w35ijj5amh6.nc",
    "https://caltech.box.com/shared/static/h3c8rlpctxpq3uh1r01zhips426lgi0e.nc",
            ]
FILE_PATHs = [
    "vmro3_input4MIPs_ozone_CMIP_UReading-CCMI-1-0_gn_195001-199912.nc",
    "vmro3_input4MIPs_ozone_CMIP_UReading-CCMI-1-0_gn_200001-201412.nc",
             ]

const H_EARTH = 7000.0
const P0 = 1e5
const HPA_TO_PA = 100.0

Plvl_inv(P) = -H_EARTH * log(P / P0)

function create_ozone(infile_paths, outfile_path; small = false)
    ncin = NCDataset(infile_paths, aggdim = "time")
    ncout = NCDataset(outfile_path, "c")

    THINNING_FACTOR = 1
    MAX_TIME = length(ncin["time"])
    FT = Float32

    if small
        THINNING_FACTOR = 6
        MAX_TIME = 12
    end

    defDim(ncout, "lon", Int(ceil(length(ncin["lon"]) // THINNING_FACTOR)))
    defDim(ncout, "lat", Int(ceil(length(ncin["lat"]) // THINNING_FACTOR)))
    defDim(ncout, "z", Int(ceil(length(ncin["plev"]) // THINNING_FACTOR)))
    defDim(ncout, "time", MAX_TIME)

    lon = defVar(ncout, "lon", FT, ("lon",), attrib = ncin["lon"].attrib)
    lon[:] = Array(ncin["lon"])[begin:THINNING_FACTOR:end]

    lat = defVar(ncout, "lat", FT, ("lat",), attrib = ncin["lat"].attrib)
    lat[:] = Array(ncin["lat"])[begin:THINNING_FACTOR:end]

    z = defVar(ncout, "z", FT, ("z",))
    plevin = ncin["plev"][begin:THINNING_FACTOR:end] .* HPA_TO_PA
    @. z = Plvl_inv(plevin)
    z.attrib["long_name"] = "altitude"
    z.attrib["units"] = "meters"

    time_ = defVar(ncout, "time", FT, ("time",), attrib = ncin["time"].attrib)
    time_[:] = Array(ncin["time"])[begin:MAX_TIME]

    defVar(
        ncout,
        "vmro3",
        FT,
        ("lon", "lat", "z", "time"),
        attrib = ncin["vmro3"].attrib,
    )
    ncout["vmro3"][:,:,:,:] = ncin["vmro3"][begin:THINNING_FACTOR:end,begin:THINNING_FACTOR:end,begin:THINNING_FACTOR:end,begin:MAX_TIME]

    close(ncin)
    close(ncout)
end

output_dir = "ozone_artifact"

if isdir(output_dir)
    @warn "$output_dir already exists. Content will end up in the artifact and may be overwritten."
    @warn "Abort this calculation, unless you know what you are doing."
else
    mkdir(output_dir)
end

foreach(zip(FILE_PATHs, FILE_URLs)) do (path, url)
    if !isfile(path)
    @info "$path not found, downloading it (might take a while)"
        ozone_file = Downloads.download(url)
        Base.mv(ozone_file, path)
    end
end

create_ozone(FILE_PATHs, joinpath(output_dir, "ozone_concentrations.nc"))

@info "Data file generated!"
create_artifact_guided(output_dir; artifact_name = basename(@__DIR__))

output_dir_lowres = "ozone_artifact_lowres"

if isdir(output_dir_lowres)
    @warn "$output_dir_lowres already exists. Content will end up in the artifact and may be overwritten."
    @warn "Abort this calculation, unless you know what you are doing."
else
    mkdir(output_dir_lowres)
end

create_ozone(
    FILE_PATHs,
    joinpath(output_dir_lowres, "ozone_concentrations_lowres.nc"),
    small = true,
)

create_artifact_guided(
    output_dir_lowres;
    artifact_name = basename(@__DIR__) * "_lowres",
    append = true
)
