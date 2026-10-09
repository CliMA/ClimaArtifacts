using Downloads

using ClimaArtifactsHelper

include("reverse_lat_dim.jl")

# Other datasets for ILAMB can be found at https://www.ilamb.org/ILAMB-Data/
FILE_URLS = [
    "https://www.ilamb.org/ILAMB-Data/DATA/hfls/FLUXCOM/hfls.nc",
    "https://www.ilamb.org/ILAMB-Data/DATA/hfss/FLUXCOM/hfss.nc",
]

FILE_PATHS = ["hfls.nc", "hfss.nc"]

output_dir = basename(@__DIR__) * "_artifact"

FILE_OUTPUTS = [
    output_dir * output_name for
    output_name in ["/hfls_FLUXCOM_hfls.nc", "/hfss_FLUXCOM_hfss.nc"]
]

preprocess_dict =
    Dict("hfls.nc" => hfls_reverse_dim, "hfss.nc" => hfss_reverse_dim)

if isdir(output_dir)
    @warn "$output_dir already exists. Content will end up in the artifact and may be overwritten."
    @warn "Abort this calculation, unless you know what you are doing."
else
    mkdir(output_dir)
end

for (file_path, file_url, file_output) in zip(FILE_PATHS, FILE_URLS, FILE_OUTPUTS)
    if !isfile(file_path)
        @info "$file_path not found, downloading it (might take a while)"
        downloader = Downloads.Downloader()
        downloaded_file = Downloads.download(file_url; downloader, progress = download_rate_callback())
        Base.mv(downloaded_file, file_path)
    end
    if haskey(preprocess_dict, file_path)
        preprocess_dict[file_path]()
    end
    mv(file_path, file_output, force = true)
end

create_artifact_guided(
    output_dir;
    artifact_name = basename(@__DIR__),
)
