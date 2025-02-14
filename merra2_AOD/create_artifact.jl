using NCDatasets
using Dates
using ClimaArtifactsHelper
using Downloads

const OUTPUT_PATH = "MERRA2_AOD.nc"

const SPLIT_FILES_DIR = "monthly_data"

isdir(SPLIT_FILES_DIR) || mkdir(SPLIT_FILES_DIR)

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
file_paths = [joinpath(SPLIT_FILES_DIR, "$(date).nc")
    for date in Dates.Date(1980, 1):Dates.Month(1):Dates.Date(2024, 12)]

@assert length(file_paths) == length(downloads_dict)

isfile(OUTPUT_PATH) && rm(OUTPUT_PATH)
ds_out = NCDataset(OUTPUT_PATH, "c")
ds_agg = NCDataset(file_paths, "r"; aggdim = "time")
for (d, n) in ds_agg.dim
    defDim(ds_out, d, n)
end
for (varname, var) in ds_agg
    if varname in ["lat", "lon", "time"]
        defVar(ds_out, varname, Float32, (varname,), attrib = var.attrib)
        if varname == "time"
            ds_out[varname][:] = var[:] .+ Dates.Day(14)
        else
            ds_out[varname][:] = var[:]
        end
    else
        defVar(ds_out, varname, Float32, dimnames(var), attrib = var.attrib)
        # both data vars are unitless
        ds_out[varname].attrib["units"] = ""
        for i = 1:ds_agg.dim["time"]
            ds_out[varname][:, :, i] = var[:, :, i]
        end
    end
end
close(ds_agg)

for (varname, var) in ds_out
    @assert all(.!ismissing.(var[:]))
    if eltype(var[:]) <: Union{Missing,Number}
        @assert all(.!isnan.(var[:]))
        @assert all(.!isinf.(var[:]))
        if !(varname in ["lat", "lon", "time"])
            @assert all(0.0 .<= var[:])
        end
    end
    if varname == "time"
        @assert all(Day(28) .<= diff(var[:]) .<= Day(31))
    end
end

@assert all(ds_out["TOTSCATAU"][:] .<= ds_out["TOTEXTTAU"][:])

close(ds_out)
create_artifact_guided_one_file(OUTPUT_PATH; artifact_name = "merra2_AOD")
