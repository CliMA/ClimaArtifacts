using Downloads
using ClimaArtifactsHelper
using NCDatasets
using Dates
include("process_downloads.jl")


# Around 30GB of storage is required to create this artifact.
# Set data_dir to the location of the data, or where you want to store it
const DATA_DIR = ""
const DOWNLOAD_FILE_NAME =
    joinpath(DATA_DIR, "era5_monthly_averages_single_level_197901-202410.nc")
const DOWNLOAD_FILES_HOURLY_DIR = joinpath(DATA_DIR, "hourly_data_parts/")

const OUTPUT_FILE_NAME_SURFACE = "era5_monthly_averages_surface_single_level_197901-202410.nc"
const OUTPUT_FILE_NAME_ATMOS = "era5_monthly_averages_atmos_single_level_197901-202410.nc"
const OUTPUT_FILE_HOURLY_NAME_SURFACE = "era5_monthly_averages_surface_single_level_hourly_197901-202410.nc"
const OUTPUT_FILE_HOURLY_NAME_ATMOS = "era5_monthly_averages_atmos_single_level_hourly_197901-202410.nc"

const OUTPUT_DIR_SURFACE = joinpath(DATA_DIR, "surface_" * basename(@__DIR__) * "_artifact")
const OUTPUT_DIR_ATMOS = joinpath(DATA_DIR, "atmos_" * basename(@__DIR__) * "_artifact")
const OUTPUT_DIR_HOURLY_SURFACE =
    joinpath(DATA_DIR, "surface_" * basename(@__DIR__) * "_hourly_artifact")
const OUTPUT_DIR_HOURLY_ATMOS =
    joinpath(DATA_DIR, "atmos_" * basename(@__DIR__) * "_hourly_artifact")
cds_PAT = ""
for dir in [
    OUTPUT_DIR_SURFACE,
    OUTPUT_DIR_ATMOS,
    OUTPUT_DIR_HOURLY_SURFACE,
    OUTPUT_DIR_HOURLY_ATMOS,
]
    if isdir(dir)
        @warn "$dir already exists. Content will end up in the artifact and may be overwritten."
        @warn "Abort this calculation, unless you know what you are doing."
    else
        @info "Creating directory $dir"
        mkdir(dir)
    end
end
##########################################################################################
# download and process data for the monthly averages
if !isfile(DOWNLOAD_FILE_NAME)
    @info "$DOWNLOAD_FILE_NAME not found, downloading it (might take a while)"
    if isfile(homedir() * "/.cdsapirc")
        run(`python download_monthly_data.py -t $DOWNLOAD_FILE_NAME`)
    else
        println("Enter your CDS Personal Access Token:")
        cds_PAT = readline()
        println("Downloading data with CDS API using PAT: $cds_PAT")
        run(`python download_monthly_data.py -k $cds_PAT -t $DOWNLOAD_FILE_NAME`)
    end
end

@info "Processing data for the monthly averages"
input_ds = NCDataset(DOWNLOAD_FILE_NAME, "r")
output_path = joinpath(OUTPUT_DIR_SURFACE, OUTPUT_FILE_NAME_SURFACE)
create_monthly_ds_surface(input_ds, output_path)
output_path = joinpath(OUTPUT_DIR_ATMOS, OUTPUT_FILE_NAME_ATMOS)
create_monthly_ds_atmos(input_ds, output_path)
close(input_ds)
@info "Data for the monthly averages processed"
# #########################################################################################
# download and process data for the monthly averages by hour
year_paths =
    [joinpath(DOWNLOAD_FILES_HOURLY_DIR, string(year) * ".nc") for year = 1979:2024]

if !all(isfile, year_paths)
    @info "Data for 1979-2024 not found in $DOWNLOAD_FILES_HOURLY_DIR, downloading and populatinit (might take a while)"
    if isfile(homedir() * "/.cdsapirc")
        run(`python download_monthly_hourly_data.py -d $DOWNLOAD_FILES_HOURLY_DIR`)
    else
        if cds_PAT == ""
            println("Enter your CDS Personal Access Token:")
            cds_PAT = readline()
        end
        println("Downloading data with CDS API using PAT: $cds_PAT")
        run(
            `python download_monthly_hourly_data.py -k $cds_PAT -d $DOWNLOAD_FILES_HOURLY_DIR`,
        )
    end
end

@info "Processing data for the monthly averages by hour"
input_ds = NCDataset(year_paths[end], "r")
output_path = joinpath(DOWNLOAD_FILES_HOURLY_DIR, "current_year.nc")
fix_current_year(input_ds, output_path)
close(input_ds)
year_paths[end] = output_path

input_ds = NCDataset(year_paths; aggdim = "time", deferopen = false)
output_path = joinpath(OUTPUT_DIR_HOURLY_SURFACE, OUTPUT_FILE_HOURLY_NAME_SURFACE)
process_hourly_data_surface(input_ds, output_path)

output_path = joinpath(OUTPUT_DIR_HOURLY_ATMOS, OUTPUT_FILE_HOURLY_NAME_ATMOS)
process_hourly_data_atmos(input_ds, output_path)
close(input_ds)

create_artifact_guided(
    OUTPUT_DIR_SURFACE;
    artifact_name = "era5_monthly_averages_surface_single_level_1979_2024",
)
create_artifact_guided(
    OUTPUT_DIR_ATMOS;
    artifact_name = "era5_monthly_averages_atmos_single_level_1979_2024",
    append = true,
)
create_artifact_guided(
    OUTPUT_DIR_HOURLY_SURFACE;
    artifact_name = "era5_monthly_averages_surface_single_level_1979_2024_hourly",
    append = true,
)
create_artifact_guided(
    OUTPUT_DIR_HOURLY_ATMOS;
    artifact_name = "era5_monthly_averages_atmos_single_level_1979_2024_hourly",
    append = true,
)
