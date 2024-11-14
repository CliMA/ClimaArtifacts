using ClimaArtifactsHelper
using NCDatasets
import OrderedCollections: OrderedDict

include("thin_and_postprocess_artifact.jl")
include("postprocess_and_make_weekly_lai_data.jl")
include("find_correct_order.jl")

# Get all the files that end with .nc and sort them with respect to time
file_paths = readdir()
nc_paths = filter(file_path -> endswith(file_path, ".nc"), file_paths)

# Check if all three files (one for each four months) exist
length(nc_paths) != 3 && error(
    "Did not find three .nc files (one for each four months). Rerun Python script or check that all files are downloaded in this directory.",
)
nc_paths = find_correct_order(nc_paths)

# Merge dataset across time dimension
mfds = NCDataset(nc_paths, aggdim = "valid_time")

# Create artifacts
file_name = "era5_2008_1.0x1.0.nc"
file_name_lowres = "era5_2008_1.0x1.0_lowres.nc"
thinning_factors = [1, 8]
for (fileout, thinning_factor) in zip([file_name, file_name_lowres], thinning_factors)
    thin_and_postprocess_artifact(mfds, fileout, THINNING_FACTOR = thinning_factor)
end

file_name_lai = "era5_2008_1.0x1.0_lai.nc"
postprocess_and_make_weekly_lai_data(mfds, file_name_lai)

close(mfds)

# Create directory and move artifacts
output_dir = basename(@__DIR__) * "_artifact"
if isdir(output_dir)
    @warn "$output_dir already exists. Content will end up in the artifact and may be overwritten."
    @warn "Abort this calculation, unless you know what you are doing."
else
    mkdir(output_dir)
end

output_dir_lowres = basename(@__DIR__) * "_lowres"
if isdir(output_dir_lowres)
    @warn "$output_dir_lowres already exists. Content will end up in the artifact and may be overwritten."
    @warn "Abort this calculation, unless you know what you are doing."
else
    mkdir(output_dir_lowres)
end

output_dir_lai = basename(@__DIR__) * "_lai"
if isdir(output_dir_lai)
    @warn "$output_dir_lai already exists. Content will end up in the artifact and may be overwritten."
    @warn "Abort this calculation, unless you know what you are doing."
else
    mkdir(output_dir_lai)
end

Base.mv(file_name, joinpath(output_dir, file_name), force = true)
Base.mv(file_name_lowres, joinpath(output_dir_lowres, file_name_lowres), force = true)
Base.mv(file_name_lai, joinpath(output_dir_lai, file_name_lai), force = true)

@info "Data files generated!"

create_artifact_guided(output_dir; artifact_name = basename(@__DIR__))
create_artifact_guided(
    output_dir_lowres;
    artifact_name = basename(@__DIR__) * "_lowres",
    append = true,
)

create_artifact_guided(
    output_dir_lai;
    artifact_name = basename(@__DIR__) * "_lai",
    append = true,
)
