using Downloads

using ClimaArtifactsHelper

const FILE_URLS = [
    "https://gml.noaa.gov/webdata/ccgg/trends/co2/co2_mm_mlo.txt",
    "https://gml.noaa.gov/webdata/ccgg/trends/co2/co2_daily_mlo.txt",
]

const FILE_PATHS = ["co2_mm_mlo.txt", "co2_daily_mlo.txt"]

output_dir = basename(@__DIR__) * "_artifact"
if isdir(output_dir)
    @warn "$output_dir already exists. Content will end up in the artifact and may be overwritten."
    @warn "Abort this calculation, unless you know what you are doing."
else
    mkdir(output_dir)
end

for (file_path, file_url) in zip(FILE_PATHS, FILE_URLS)
    println(file_url)
    println(file_path)
    if !isfile(file_path)
        @info "$file_path not found, downloading it (might take a while)"
        downloader = Downloads.Downloader()
        println(file_url)
        println(file_path)
        downloaded_file = Downloads.download(file_url; downloader, progress = download_rate_callback())
        Base.mv(downloaded_file, file_path)
    end
end

for file_path in FILE_PATHS
    output_path = joinpath(output_dir, basename(file_path))
    # set force to true to overwrite existing output files
    Base.cp(file_path, output_path; force=true)
end

create_artifact_guided(
    output_dir;
    artifact_name = basename(@__DIR__),
)
