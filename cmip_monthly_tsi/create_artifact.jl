using Dates
using Downloads
using NCDatasets
using CSV

using ClimaArtifactsHelper

const FILE_URLs = [
    # monthly resolution reference solar forcing from 1850-2023
    "https://cloud.iaa.es/index.php/s/n7cacmRBjk5Gb8f/download/multiple_input4MIPs_solar_CMIP_SOLARIS-HEPPA-CMIP-4-6_gn_185001-202312.nc.gz",
    # future solar forcing dataset (2022-2299)
    "https://cloud.iaa.es/index.php/s/QWorEALDriYabgN/download/multiple_input4MIPs_solar_ScenarioMIP_SOLARIS-HEPPA-ScenarioMIP-4-6-a002_gn_202201-229912.nc",
]

# First one is compressed, but the second one is not
const FILE_PATHs = ["solar_forcing_1850-2023.nc.gz", "solar_forcing_2022-2299.nc"]

# Download data
foreach(zip(FILE_PATHs, FILE_URLs)) do (path, url)
    if !isfile(path)
        @info "$path not found, downloading it"
        tsi_file = Downloads.download(url)
        Base.mv(tsi_file, path)
    end
end

# Uncompress gz file
gz_filepath = first(FILE_PATHs)
run(`gzip -fd $gz_filepath`)
FILE_PATHs[1] = replace(FILE_PATHs[1], ".gz" => "")

# Create CSV file from NetCDF files
historical_tsi_nc = NCDataset(FILE_PATHs[1])
future_tsi_nc = NCDataset(FILE_PATHs[2])

# Find index to combine the two datasets
historical_dates = Array(historical_tsi_nc["time"][:])
future_dates = Array(future_tsi_nc["time"][:])
next_date = last(historical_dates) + Dates.Month(1)
idx = findfirst(==(next_date), future_dates)

# Combine data from the two NetCDF files
historical_tsi = Array(historical_tsi_nc["tsi"][:])
future_tsi = Array(future_tsi_nc["tsi"][:])

combined_dates = vcat(historical_dates, future_dates[idx:end])
combined_tsi = vcat(historical_tsi, future_tsi[idx:end])

close(historical_tsi_nc)
close(future_tsi_nc)

@assert allunique(combined_dates)
@assert length(combined_dates) == length(combined_tsi)
@assert all(
    combined_dates[i] + Month(1) == combined_dates[i+1] for
    i = firstindex(combined_dates):(lastindex(combined_dates)-1)
)

artifact_filename = "cmip_monthly_tsi.csv"
open(artifact_filename, "w") do io
    write(io, "Date,Total Solar Irradiance W m^-2\n")
    for (date, tsi) in zip(combined_dates, combined_tsi)
        write(io, "$date,$tsi\n")
    end
end

# Create artifact
output_dir = basename(@__DIR__) * "_artifact"
if isdir(output_dir)
    @warn "$output_dir already exists. Content will end up in the artifact and may be overwritten."
    @warn "Abort this calculation, unless you know what you are doing."
else
    mkdir(output_dir)
end

Base.mv(artifact_filename, joinpath(output_dir, artifact_filename), force = true)

@info "Data files generated!"

create_artifact_guided(output_dir; artifact_name = basename(@__DIR__))
