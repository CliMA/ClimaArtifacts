################################################################################
# IMPORTS                                                                      #
################################################################################

using JSON

using Formatting
using Statistics
using Dates
using DataFrames
using CSV
using Downloads

using ClimaArtifactsHelper


################################################################################
# CONSTANTS                                                                    #
################################################################################

OUTPUT_DIR = "modis_lai_fluxnet_sites_artifact"

# Info for AMERIFLUX sites US-Ha1, US-MOz, US-NR1, US-Var
# PRODUCT = "MCD15A2H"
# BAND = "Lai_500m"
# NETWORK = "AMERIFLUX"
# START_DATE = "A20020704"
# END_DATE = "A20250602"

JSON_URLS = [
    "https://modis.ornl.gov/rst/api/v1/MCD15A2H/AMERIFLUX/US-Ha1/subset?band=Lai_500m&startDate=A20020704&endDate=A20250602",
    "https://modis.ornl.gov/rst/api/v1/MCD15A2H/AMERIFLUX/US-MOz/subset?band=Lai_500m&startDate=A20020704&endDate=A20250602",
    "https://modis.ornl.gov/rst/api/v1/MCD15A2H/AMERIFLUX/US-NR1/subset?band=Lai_500m&startDate=A20020704&endDate=A20250602",
    "https://modis.ornl.gov/rst/api/v1/MCD15A2H/AMERIFLUX/US-Var/subset?band=Lai_500m&startDate=A20020704&endDate=A20250602",
]

MODIS_FILE_PATHS = [
    "modis_lai_US-Ha1.csv",
    "modis_lai_US-MOz.csv",
    "modis_lai_US-NR1.csv",
    "modis_lai_US-Var.csv",
]

SITES = [
    "US-Ha1",
    "US-MOz",
    "US-NR1",
    "US-Var",
]

################################################################################
# HELPERS                                                                      #
################################################################################

"""
    single_col_data_matrix(JSON_data::Vector)
    
Takes in a vector of JSON data dicitonaries of a single column of chunked
MODIS data and assembles it into a data matrix with a time column and a
single data column. The data column gives the average of the grid cell 
arround the site for each day, and the time column gives the Dates.DateTime 
object for each day. In averaging, MODIS data marked as missing (>100) is 
ignored.
"""
function single_col_data_matrix(JSON_data::Vector)
    cleansed_dat = [
        [
            chunk["data"][i] < 100 ? chunk["data"][i] : missing for
            i in 1:length(chunk["data"])
        ] for chunk in JSON_data
    ]

    data_col =
        [mean(filter(!ismissing, day_dat)) / 10 for day_dat in cleansed_dat]

    time_col =
        [DateTime(JSON_data[i]["calendar_date"]) for i in 1:length(JSON_data)]

    return DataFrame(date = time_col, value = data_col)
end

################################################################################
# MAIN                                                                         #
################################################################################

if isdir(OUTPUT_DIR)
    @warn "$OUTPUT_DIR already exists. Content will end up in the artifact and may be overwritten."
    @warn "Abort this calculation, unless you know what you are doing."
else
    mkdir(OUTPUT_DIR)
end

for (file_path, url, site_ID) in zip(MODIS_FILE_PATHS, JSON_URLS, SITES)
    if !isfile(file_path)
        @info "$file_path not found, downloading it (might take a while)"

        downloaded_file = Downloads.download(url; progress = download_rate_callback())

        Base.mv(downloaded_file, "modis_lai_fluxnet_sites_artifact/$(site_ID).json")
        
        # Parse JSON file as a Dict
        json_dict = open("modis_lai_fluxnet_sites_artifact/$(site_ID).json", "r") do f
            return JSON.parse(f)["subset"]
        end

        dataset = single_col_data_matrix(json_dict)

        # Write the data back to the file
        CSV.write(joinpath(OUTPUT_DIR, file_path), dataset)

        # Remove temp JSON file
        Base.rm("modis_lai_fluxnet_sites_artifact/$(site_ID).json")
    end
end

create_artifact_guided(OUTPUT_DIR, artifact_name = basename(@__DIR__))