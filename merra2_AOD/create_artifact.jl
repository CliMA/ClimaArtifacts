using NCDatasets
using Dates
using ClimaArtifactsHelper
using Downloads
include("utilities.jl")

const OUTPUT_PATH = joinpath("highres", "MERRA2_AOD.nc")
const OUTPUT_PATH_LOWRES = joinpath("lowres", "MERRA2_AOD.nc")

THINNING_FACTOR = 3


const SPLIT_FILES_DIR = "monthly_data"

for dir in ["lowres", "highres", SPLIT_FILES_DIR]
    isdir(dir) || mkdir(dir)
end

# dict from month to download url
downloads_dict = Dict()

open("download_urls.txt") do file
    for line in eachline(file)
        url_date = Dates.Date(match(r"(\d{6})\.SUB", line)[1], "yyyymm")
        downloads_dict[url_date] = line
    end
end

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

for date = Dates.Date(1980, 1):Dates.Month(1):Dates.Date(2024, 12)
    outfile_path = joinpath(SPLIT_FILES_DIR, "$(date).nc")
    if !isfile(outfile_path)
        if haskey(downloads_dict, date)
            url = downloads_dict[date]
            try
                downloaded_file = Downloads.download(url; downloader)
                Base.mv(downloaded_file, outfile_path)
            catch e
                @warn "Error downloading $url: $e"
                sleep(60)
            end
        else
            @warn "No download URL found for $date"
        end
    end
end

# Merge all the files into a single file
file_paths = [
    joinpath(SPLIT_FILES_DIR, "$(date).nc") for
    date = Dates.Date(1980, 1):Dates.Month(1):Dates.Date(2024, 12)
]

@assert length(file_paths) == length(downloads_dict)
@info "All files downloaded. Merging..."

isfile(OUTPUT_PATH) && rm(OUTPUT_PATH)
isfile(OUTPUT_PATH_LOWRES) && rm(OUTPUT_PATH_LOWRES)

ds_out = NCDataset(OUTPUT_PATH, "c")
ds_agg = NCDataset(file_paths, "r"; aggdim = "time")
ds_copyto!(ds_out, ds_agg)
close(ds_agg)

@info "Full resolution file created. Thinning..."
ds_small = NCDataset(OUTPUT_PATH_LOWRES, "c")
thin_AOD_ds!(ds_small, ds_out, THINNING_FACTOR)
close(ds_out)
close(ds_small)

create_artifact_guided_one_file(OUTPUT_PATH; artifact_name = "merra2_AOD")
create_artifact_guided_one_file(
    OUTPUT_PATH_LOWRES;
    artifact_name = "merra2_AOD_lowres",
    append = true,
)
