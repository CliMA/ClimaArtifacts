using Downloads
using ClimaArtifactsHelper

const FILE_URL_30ARCSEC = "https://www.ngdc.noaa.gov/thredds/fileServer/global/ETOPO2022/30s/30s_bed_elev_netcdf/ETOPO_2022_v1_30s_N90W180_bed.nc"
const FILE_URL_60ARCSEC = "https://www.ngdc.noaa.gov/thredds/fileServer/global/ETOPO2022/60s/60s_bed_elev_netcdf/ETOPO_2022_v1_60s_N90W180_bed.nc"

const FILE_PATH_30ARCSEC = "ETOPO_2022_v1_30s_N90W180_bed.nc"
const FILE_PATH_60ARCSEC = "ETOPO_2022_v1_60s_N90W180_bed.nc"

output_dir_30arcsec =  "bedrock_depth_30arcsec"*"_artifact"
output_dir_60arcsec =  "bedrock_depth_60arcsec"*"_artifact"

if isdir(output_dir_30arcsec)
    @warn "$output_dir already exists. Content will end up in the artifact and may be overwritten."
    @warn "Abort this calculation, unless you know what you are doing."
else
    mkdir(output_dir_30arcsec)
end

# 30 ARC SECOND DATA
path = FILE_PATH_30ARCSEC
url = FILE_URL_30ARCSEC
downloader = Downloads.Downloader()
if !isfile(path)
    @info "$path not found, downloading it (might take a while)"
    downloaded_file = Downloads.download(url; progress = download_rate_callback())
    Base.mv(downloaded_file, path)
end
Base.cp(path, joinpath(output_dir_30arcsec, basename(path)))
create_artifact_guided(output_dir_30arcsec; artifact_name = basename(@__DIR__) * "_30arcseconds")

if isdir(output_dir_60arcsec)
    @warn "$output_dir already exists. Content will end up in the artifact and may be overwritten."
    @warn "Abort this calculation, unless you know what you are doing."
else
    mkdir(output_dir_60arcsec)
end

# 60 ARC SECOND DATA
path = FILE_PATH_60ARCSEC
url = FILE_URL_60ARCSEC
downloader = Downloads.Downloader()
if !isfile(path)
    @info "$path not found, downloading it (might take a while)"
    downloaded_file = Downloads.download(url; progress = download_rate_callback())
    Base.mv(downloaded_file, path)
end
Base.cp(path, joinpath(output_dir_60arcsec, basename(path)))
create_artifact_guided(output_dir_60arcsec; artifact_name = basename(@__DIR__) * "_60arcseconds", append = true)

@info "Generated bedrock depth files"
