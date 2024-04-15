using Downloads

using ClimaArtifactsHelper

const FILE_URL = "https://svn-ccsm-inputdata.cgd.ucar.edu/trunk/inputdata/lnd/clm2/surfdata_map/surfdata_0.9x1.25_hist_16pfts_nourb_CMIP6_simyrPtVg_c181114.nc"
const FILE_PATH = "surfdata_0.9x1.25_hist_16pfts_nourb_CMIP6_simyrPtVg_c181114.nc"

output_dir = basename(@__DIR__) * "_artifact"
if isdir(output_dir)
    @warn "$output_dir already exists. Content will end up in the artifact and may be overwritten."
    @warn "Abort this calculation, unless you know what you are doing."
else
    mkdir(output_dir)
end

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
    downloaded_file = Downloads.download(FILE_URL; downloader)
    Base.mv(downloaded_file, FILE_PATH)
    Base.cp(FILE_PATH, joinpath(output_dir, basename(FILE_PATH)))
end

create_artifact_guided(
    output_dir;
    artifact_name = basename(@__DIR__),
)
