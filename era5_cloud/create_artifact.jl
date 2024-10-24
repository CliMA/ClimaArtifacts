using NCDatasets
using ClimaArtifactsHelper

FILE_PATH = "era5_cloud_201001-201012.nc"

const H_EARTH = 7000.0
const P0 = 1e5
const HPA_TO_PA = 100.0

Plvl_inv(P) = -H_EARTH * log(P / P0)

function create_cloud(infile_path, outfile_path)
    ncin = NCDataset(infile_path)
    ncout = NCDataset(outfile_path, "c")

    # This artifact is for temporarily prescribing clouds in our simulations, so we
    # only need a coarse resolution. Here we resample the ERA5 data (0.25x0.25 degrees)
    # to 2x2 degrees.
    THINNING_FACTOR = 8
    FT = Float32

    defDim(ncout, "lon", Int(ceil(length(ncin["longitude"]) // THINNING_FACTOR)))
    defDim(ncout, "lat", Int(ceil(length(ncin["latitude"]) // THINNING_FACTOR)))
    defDim(ncout, "z", length(ncin["pressure_level"]))
    defDim(ncout, "date", length(ncin["date"]))

    lon_attribs = Dict(ncin["longitude"].attrib)
    lon_attribs["_FillValue"] = NaN32
    lon = defVar(ncout, "lon", FT, ("lon",), attrib = lon_attribs, deflatelevel = 9)
    lon[:] = Array(ncin["longitude"])[begin:THINNING_FACTOR:end]

    lat_attribs = Dict(ncin["latitude"].attrib)
    lat_attribs["_FillValue"] = NaN32
    lat = defVar(ncout, "lat", FT, ("lat",), attrib = lat_attribs, deflatelevel = 9)
    lat[:] = Array(ncin["latitude"])[begin:THINNING_FACTOR:end]

    z = defVar(ncout, "z", FT, ("z",), deflatelevel = 9)
    plevin = ncin["pressure_level"] .* HPA_TO_PA
    @. z = Plvl_inv(plevin)
    z.attrib["long_name"] = "altitude"
    z.attrib["units"] = "meters"

    date_ = defVar(ncout, "date", Int32, ("date",), attrib = ncin["date"].attrib, deflatelevel = 9)
    # ERA5 defines monthly mean data on the first day of the month, so we shift it by 14 days.
    date_[:] = Array(ncin["date"]) .+ Int32(14)

    cloud_names = ("cc", "clwc", "ciwc")
    for name in cloud_names
        defVar(
            ncout,
            name,
            FT,
            ("lon", "lat", "z", "date"),
            attrib = ncin[name].attrib,
            deflatelevel = 9,
        )

        ncout[name][:,:,:,:] = ncin[name][begin:THINNING_FACTOR:end,begin:THINNING_FACTOR:end,:,:]
    end

    close(ncin)
    close(ncout)
end

output_dir = "era5_cloud_artifact"

if isdir(output_dir)
    @warn "$output_dir already exists. Content will end up in the artifact and may be overwritten."
    @warn "Abort this calculation, unless you know what you are doing."
else
    mkdir(output_dir)
end

if !isfile(FILE_PATH)
    @info "$FILE_PATH not found, downloading it (might take a while)"
    run(`python download_era5.py`)
end

create_cloud(FILE_PATH, joinpath(output_dir, "era5_cloud.nc"))

@info "Data file generated!"
create_artifact_guided(output_dir; artifact_name = basename(@__DIR__))
