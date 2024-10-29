using Downloads

using ClimaArtifactsHelper

const FILE_URL = "https://downloads.psl.noaa.gov/Datasets/gpcp/precip.mon.mean.nc"
const FILE_PATH = "precip.mon.mean.nc"

output_dir = "precipitation_obs_artifact_v2"
if isdir(output_dir)
    @warn "$output_dir already exists. Content will end up in the artifact and may be overwritten."
    @warn "Abort this calculation, unless you know what you are doing."
else
    mkdir(output_dir)
end

if !isfile(FILE_PATH)
    @info "$FILE_PATH not found, downloading it (might take a while)"
    precipitation_obs_file = Downloads.download(FILE_URL)
    Base.mv(precipitation_obs_file, FILE_PATH)
    Base.cp(FILE_PATH, joinpath(output_dir, basename(FILE_PATH)))
end

@info "Data file generated!"
create_artifact_guided(output_dir; artifact_name = basename(@__DIR__))
