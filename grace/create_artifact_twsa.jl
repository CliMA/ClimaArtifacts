using Downloads

using ClimaArtifactsHelper

# Other datasets for ILAMB can be found at https://www.ilamb.org/ILAMB-Data/
FILE_URLS = [
    "https://www.ilamb.org/ILAMB-Data/DATA/twsa/GRACE/twsa_0.5x0.5.nc",
]

FILE_PATHS = ["twsa_0.5x0.5.nc",]

output_dir = basename(@__DIR__) * "_artifact"

FILE_OUTPUTS = [
    output_dir * output_name for output_name in
    ["/twsa_0.5x0.5.nc"]
]

if isdir(output_dir)
    @warn "$output_dir already exists. Content will end up in the artifact and may be overwritten."
    @warn "Abort this calculation, unless you know what you are doing."
else
    mkdir(output_dir)
end

for (file_path, file_url, file_output) in zip(FILE_PATHS, FILE_URLS, FILE_OUTPUTS)
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
    mv(file_path, file_output, force = true)
end

create_artifact_guided(
    output_dir;
    artifact_name = basename(@__DIR__),
)
