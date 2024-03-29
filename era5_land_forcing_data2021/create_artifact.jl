using Downloads

using ClimaArtifactsHelper

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

@info "Data file generated!"

create_artifact_guided(output_dir; artifact_name = basename(@__DIR__))
