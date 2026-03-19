using Downloads
using CodecZlib
using ClimaArtifactsHelper

const FILE_URL = "https://pmm.nasa.gov/sites/default/files/downloads/IMERG_land_sea_mask.nc.gz"
const FILE_PATH_GZ = "IMERG_land_sea_mask.nc.gz"
const FILE_PATH_NC = "IMERG_land_sea_mask.nc"

output_dir = basename(@__DIR__) * "_artifact"
if isdir(output_dir)
    @warn "$output_dir already exists. Content will end up in the artifact and may be overwritten."
    @warn "Abort this calculation, unless you know what you are doing."
else
    mkdir(output_dir)
end

if !isfile(FILE_PATH_GZ)
    @info "$FILE_PATH_GZ not found, downloading it (might take a while)"
    downloaded_file = Downloads.download(FILE_URL; progress = download_rate_callback())
    Base.mv(downloaded_file, FILE_PATH_GZ)
end

if !isfile(FILE_PATH_NC)
    @info "Decompressing $FILE_PATH_GZ"
    open(FILE_PATH_GZ, "r") do compressed
        open(FILE_PATH_NC, "w") do decompressed
            write(decompressed, GzipDecompressorStream(compressed))
        end
    end
end

output_filepath = joinpath(output_dir, FILE_PATH_NC)
cp(FILE_PATH_NC, output_filepath, force = true)

@info "Data file generated!"
create_artifact_guided(output_dir; artifact_name = basename(@__DIR__))
