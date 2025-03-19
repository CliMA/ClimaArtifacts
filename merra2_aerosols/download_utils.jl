using Downloads
using Interpolations
using Dates
using ClimaArtifactsHelper


downloader = Downloads.Downloader()
# This relies on certain Earthdata prerequisite files
# see: https://disc.gsfc.nasa.gov/information/howto?title=How%20to%20Generate%20Earthdata%20Prerequisite%20Files
downloader.easy_hook =
    (easy, info) -> begin
        Downloads.Curl.setopt(easy, Downloads.Curl.CURLOPT_LOW_SPEED_TIME, 0)
        Downloads.Curl.setopt(easy, Downloads.Curl.CURLOPT_NETRC, 1)
        Downloads.Curl.setopt(
            easy,
            Downloads.Curl.CURLOPT_COOKIEJAR,
            joinpath(homedir(), ".urs_cookies"),
        )
        Downloads.Curl.setopt(
            easy,
            Downloads.Curl.CURLOPT_COOKIEFILE,
            joinpath(homedir(), ".urs_cookies"),
        )
        Downloads.Curl.setopt(easy, Downloads.Curl.CURLOPT_FOLLOWLOCATION, 1)
        Downloads.Curl.setopt(easy, Downloads.Curl.CURLOPT_FOLLOWLOCATION, 1)

    end

function download_earthdata(url, outfile_path)
    try
        downloaded_file = Downloads.download(url; downloader)
        Base.mv(downloaded_file, outfile_path)
    catch e
        @warn "Error downloading $url: $e"
        sleep(600)
    end
end
