using Downloads
using ClimaArtifactsHelper
include("subset_of_data.jl")

const DOWNLOAD_FILE_NAME = "era5_monthly_averages_200801-200812.nc"

const OUTPUT_FILE_HOURLY_NAME = "era5_monthly_averages_hourly_200801-200812.nc"
const OUTPUT_FILE_NAME = "era5_monthly_averages_200801-200812.nc"

# create two artifacts in two folders
output_dir = basename(@__DIR__) * "_artifact"
output_dir_hourly = basename(@__DIR__) * "_hourly_artifact"
if isdir(output_dir)
    @warn "$output_dir already exists. Content will end up in the artifact and may be overwritten."
    @warn "Abort this calculation, unless you know what you are doing."
else
    mkdir(output_dir)
end
if isdir(output_dir_hourly)
    @warn "$output_dir_hourly already exists. Content will end up in the artifact and may be overwritten."
    @warn "Abort this calculation, unless you know what you are doing."
else
    mkdir(output_dir_hourly)
end
if !isfile(DOWNLOAD_FILE_NAME)
    @info "$DOWNLOAD_FILE_NAME not found, downloading it (might take a while)"
    if isfile(homedir() * "/.cdsapirc")
        run(`python download_data.py`)
    else
        println("Enter your CDS Personal Access Token:")
        cds_PAT = readline()
        println("Downloading data with CDS API using PAT: $cds_PAT")
        run(`python download_data.py $cds_PAT`)
    end
end

ds = NCDataset(DOWNLOAD_FILE_NAME, "r")
# the downloaded dataset has both hourly averages and overall averages per month
# here we split the times
create_new_ds_from_time_indx(ds, [i for i = 1:12], joinpath(output_dir, OUTPUT_FILE_NAME))
create_new_ds_from_time_indx(
    ds,
    [i for i = 13:ds.dim["time"]],
    joinpath(output_dir_hourly, OUTPUT_FILE_HOURLY_NAME),
)
close(ds)
create_artifact_guided(output_dir; artifact_name = basename(@__DIR__))
create_artifact_guided(
    output_dir_hourly;
    artifact_name = basename(@__DIR__) * "_hourly",
    append = true,
)
