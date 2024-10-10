using Downloads

using ClimaArtifactsHelper

const FILE_URL = "https://gml.noaa.gov/webdata/ccgg/trends/co2/co2_mm_mlo.txt"

const FILE_PATH = "co2_mm_mlo.txt"

output_dir = basename(@__DIR__) * "_artifact"
if isdir(output_dir)
    @warn "$output_dir already exists. Content will end up in the artifact and may be overwritten."
    @warn "Abort this calculation, unless you know what you are doing."
else
    mkdir(output_dir)
end

println(FILE_URL)
println(FILE_PATH)
if !isfile(FILE_PATH)
    @info "$FILE_PATH not found, downloading it (might take a while)"
    # The server has poor certificates, so we have to disable verification
    downloader = Downloads.Downloader()
    downloader.easy_hook =
        (easy, info) -> Downloads.Curl.setopt(
            easy,
            Downloads.Curl.CURLOPT_SSL_VERIFYPEER,
            false,
        )
    println(FILE_URL)
    println(FILE_PATH)
    downloaded_file = Downloads.download(FILE_URL; downloader)
    Base.mv(downloaded_file, FILE_PATH)
end

output_path = joinpath(output_dir, basename(FILE_PATH))
# set force to true to overwrite existing output files
Base.cp(FILE_PATH, output_path; force=true)

create_artifact_guided(
    output_dir;
    artifact_name = basename(@__DIR__),
)
