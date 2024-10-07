using Downloads
using ClimaArtifactsHelper

const FILE_URLS = [
"https://www.ngdc.noaa.gov/thredds/fileServer/global/ETOPO2022/30s/30s_surface_elev_netcdf/ETOPO_2022_v1_30s_N90W180_surface.nc",
"https://www.ngdc.noaa.gov/thredds/fileServer/global/ETOPO2022/60s/60s_surface_elev_netcdf/ETOPO_2022_v1_60s_N90W180_surface.nc",
]

const FILE_PATHS = [
"ETOPO_2022_v1_30s_N90W180_surface.nc",
"ETOPO_2022_v1_60s_N90W180_surface.nc",
]

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
        # The server has poor certificates, so we have to disable verification
        downloader = Downloads.Downloader()
        downloader.easy_hook =
            (easy, info) -> Downloads.Curl.setopt(
                easy,
                Downloads.Curl.CURLOPT_SSL_VERIFYPEER,
                false,
            )
        println(file_url)
        println(file_path)
        downloaded_file = Downloads.download(file_url; downloader)
        Base.mv(downloaded_file, file_path)
    end
end

@info "Generated earth orography files"
create_artifact_guided(output_dir; artifact_name = basename(@__DIR__))
