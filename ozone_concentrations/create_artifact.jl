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

function create_ozone(infile_paths, outfile_path)
    FT = Float32

    ncin = NCDataset(infile_paths, aggdim = "time")
    ncout = NCDataset(outfile_path, "c")

    defDim(ncout, "lon", length(ncin["lon"]))
    defDim(ncout, "lat", length(ncin["lat"]))
    defDim(ncout, "z", length(ncin["plev"]))
    defDim(ncout, "time", length(ncin["time"]))

    lon = defVar(ncout, "lon", FT, ("lon",), attrib = ncin["lon"].attrib)
    lon[:] = Array(ncin["lon"])

    lat = defVar(ncout, "lat", FT, ("lat",), attrib = ncin["lat"].attrib)
    lat[:] = Array(ncin["lat"])

    z = defVar(ncout, "z", FT, ("z",))
    plevin = ncin["plev"][:] .* HPA_TO_PA
    @. z = Plvl_inv(plevin)
    z.attrib["long_name"] = "altitude"
    z.attrib["units"] = "meters"

    time_ = defVar(ncout, "time", FT, ("time",), attrib = ncin["time"].attrib)
    time_[:] = Array(ncin["time"])

    defVar(
        ncout,
        "vmro3",
        FT,
        ("lon", "lat", "z", "time"),
        attrib = ncin["vmro3"].attrib,
    )
    ncout["vmro3"][:,:,:,:] = ncin["vmro3"][:,:,:,:]

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
