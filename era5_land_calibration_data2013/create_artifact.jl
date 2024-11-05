using ClimaArtifactsHelper
using NCDatasets

include("thin_and_clean_artifact.jl")
include("find_correct_order.jl")

# Get all the files that end with .nc and sort them with respect to time
file_paths = readdir()
nc_paths = filter(file_path -> endswith(file_path, ".nc"), file_paths) |> sort
nc_paths = find_correct_order(nc_paths)

# Merge dataset across time dimension
mfds = NCDataset(nc_paths, aggdim = "valid_time")

# Create artifacts
file_name = "era5_land_calibration_2013_1.0x1.0.nc"
thin_and_clean_artifact(mfds, fileout, THINNING_FACTOR = 1)

# Create directory and move artifacts
output_dir = basename(@__DIR__) * "_artifact"
if isdir(output_dir)
    @warn "$output_dir already exists. Content will end up in the artifact and may be overwritten."
    @warn "Abort this calculation, unless you know what you are doing."
else
    mkdir(output_dir)
end

Base.mv(file_name, joinpath(output_dir, file_name), force = true)

@info "Data files generated!"

create_artifact_guided(output_dir; artifact_name = basename(@__DIR__))
