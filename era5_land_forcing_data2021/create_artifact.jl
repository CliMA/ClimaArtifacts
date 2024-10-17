using Downloads
using NCDatasets
using ClimaArtifactsHelper

# This file is 20GB

# TODO: Add link from original source

output_dir = "era5_land_forcing2021_artifact"
const FILE_URL = "https://caltech.box.com/shared/static/yi4dlo9wug9a4yz2ckqfiqh26a61u55y.nc"
const FILE_PATH = joinpath(output_dir, "era5_2021_0.9x1.25.nc")

if isdir(output_dir)
    @warn "$output_dir already exists. Content will end up in the artifact and may be overwritten."
    @warn "Abort this calculation, unless you know what you are doing."
else
    mkdir(output_dir)
end

if !isfile(FILE_PATH)
    @info "$FILE_PATH not found, downloading it (might take a while)"
    forcing_file = Downloads.download(FILE_URL)
    Base.mv(forcing_file, FILE_PATH)
end

@info "Raw data file generated!"
create_artifact_guided(output_dir; artifact_name = basename(@__DIR__))


"""
   thin_artifact(
       filein,
       fileout,
       varname;
       THINNING_FACTOR = 8,
   )

Take the file in `filein` and write a thinned-down version to `fileout` for the given `varname`.

Thinning means taking one very `THINNING_FACTOR` points.
"""
function thin_artifact(filein, fileout; THINNING_FACTOR = 8)
    ncin = NCDataset(filein)
    ncout = NCDataset(fileout, "c")
    FT = Float32

    defDim(ncout, "lon", Int(ceil(length(ncin["lon"]) // THINNING_FACTOR)))
    defDim(ncout, "lat", Int(ceil(length(ncin["lat"]) // THINNING_FACTOR)))
    defDim(ncout, "time", length(Array(ncin["time"])))

    lon = defVar(
        ncout,
        "lon",
        FT,
        ("lon",),
        attrib = ncin["lon"].attrib,
        deflatelevel = 9,
    )
    lon[:] = Array(ncin["lon"])[begin:THINNING_FACTOR:end]

    lat = defVar(
        ncout,
        "lat",
        FT,
        ("lat",),
        attrib = ncin["lat"].attrib,
        deflatelevel = 9,
    )
    lat[:] = Array(ncin["lat"])[begin:THINNING_FACTOR:end]

    time_ = defVar(
        ncout,
        "time",
        FT,
        ("time",),
        attrib = ncin["time"].attrib,
        deflatelevel = 9,
    )
    # First and last year
    time_[:] = Array(ncin["time"])

    varnames = setdiff(Set(keys(ncin)), NCDatasets.dimnames(ncin))

    for varname in varnames
        @show varname
        defVar(
            ncout,
            varname,
            FT,
            ("lon", "lat", "time"),
            attrib = ncin[varname].attrib,
            deflatelevel = 9,
        )
        ncout[varname][:, :, :] = ncin[varname][
            begin:THINNING_FACTOR:end,
            begin:THINNING_FACTOR:end,
            :,
        ]
    end

    close(ncin)
    close(ncout)
end

output_dir_lowres = "$(basename(@__DIR__))_lowres"
if isdir(output_dir_lowres)
    @warn "$output_dir_lowres already exists. Content will end up in the artifact and may be overwritten."
    @warn "Abort this calculation, unless you know what you are doing."
else
    mkdir(output_dir_lowres)
end

new_nc_name = "$(FILE_PATH)_lowres.nc"
thin_artifact(
    SIC_FILE_PATH,
    joinpath(output_dir_lowres, new_nc_name),
)

create_artifact_guided(output_dir_lowres; artifact_name = basename(@__DIR__) * "_lowres", append = true)
