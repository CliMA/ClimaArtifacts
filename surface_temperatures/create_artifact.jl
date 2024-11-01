using Downloads
using NCDatasets
using ClimaArtifactsHelper
using Dates

const FILE_URL = "https://berkeley-earth-temperature.s3.us-west-1.amazonaws.com/Global/Gridded/Land_and_Ocean_LatLong1.nc"

const FILE_NAME = "Land_and_Ocean_LatLong1.nc"

function download_progress(total::Integer, now::Integer)
    if total == 0
        print("Downloaded $(round(now/10^9, digits=2)) GB \r")
    else
        print(
            "Downloaded $(round(now/10^9, digits=2)) out of $(round(total/10^9, digits=2)) GB: $(div(now * 100, total))% \r",
        )
    end
end


output_dir = basename(@__DIR__) * "_artifact"
if isdir(output_dir)
    @warn "$output_dir already exists. Content will end up in the artifact and may be overwritten."
    @warn "Abort this calculation, unless you know what you are doing."
else
    mkdir(output_dir)
end

if !isfile(FILE_NAME)
    @info "$FILE_NAME not found, downloading it (might take a while)"
    # The server has poor certificates, so we have to disable verification
    downloader = Downloads.Downloader()
    downloader.easy_hook =
        (easy, info) ->
            Downloads.Curl.setopt(easy, Downloads.Curl.CURLOPT_SSL_VERIFYPEER, false)
    println(FILE_URL)
    println(FILE_NAME)
    downloaded_file = Downloads.download(FILE_URL; downloader, progress = download_progress)
    Base.mv(downloaded_file, FILE_NAME)
end

output_path = joinpath(output_dir, FILE_NAME)
# delete the old output file if it exists
if isfile(output_path)
    Base.rm(output_path)
end
input_ds = NCDataset(FILE_NAME, "r")

# calculate absolute temperature from climatology and anomaly
climatology = input_ds["climatology"][:, :, :]
temperature_anomaly = input_ds["temperature"][:, :, :]
times = input_ds["time"][:]
temperature_absolute = similar(temperature_anomaly)
# loop through each time point, and calculate the absolute temperature at it
for t in 1:input_ds.dim["time"]
    month = ceil(Int, 12 * (times[t] % 1))
    temperature_absolute[:, :, t] .=
        climatology[:, :, month] .+ temperature_anomaly[:, :, t]
end

# create the output dataset
output_ds = NCDataset(output_path, "c")
# copy data and attributes from un-processed dataset
for (attrib_name, attrib_value) in input_ds.attrib
    output_ds.attrib[attrib_name] = attrib_value
end

defDim(output_ds, "longitude", input_ds.dim["longitude"])
defDim(output_ds, "latitude", input_ds.dim["latitude"])
defDim(output_ds, "time", input_ds.dim["time"])
defDim(output_ds, "month_number", input_ds.dim["month_number"])

for (varname, var) in input_ds
    if !(varname in ["climatology", "temperature", "time"])
        defVar(
            output_ds,
            varname,
            var,
            dimnames(var);
            attrib = var.attrib,
            deflatelevel = deflate(var)[3],
        )
    end
end
# convert time to standard
new_times = map(times) do t
    DateTime(floor(t), ceil(12 * (t % 1)), 15)
end
new_times_attribs = [
    "standard_name" => "time",
    "long_name" => "Time",
    # "units" => "days since 0001-01-01 00:00:00",
]

defVar(
    output_ds,
    "time",
    new_times,
    ("time",);
    attrib = new_times_attribs,
)
# add new variable to the output dataset
abs_temp_attrib = [
    "units" => "degree C",
    "long_name" => "Absolute Air Surface Temperature",
    "standard_name" => "absolute_temperature",
]
defVar(
    output_ds,
    "absolute_temperature",
    temperature_absolute,
    ("longitude", "latitude", "time");
    attrib = abs_temp_attrib,
    fillvalue = NaN,
    deflatelevel = deflate(input_ds["temperature"])[3],
)

close(input_ds)
close(output_ds)


create_artifact_guided(output_dir; artifact_name = basename(@__DIR__))
