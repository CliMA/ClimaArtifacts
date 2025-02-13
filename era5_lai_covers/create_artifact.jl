using ClimaArtifactsHelper
using NCDatasets
import OrderedCollections: OrderedDict

include("remove_time.jl")

# Get all the files that end with .nc
file_paths = readdir(@__DIR__)
nc_paths = filter(file_path -> endswith(file_path, ".nc"), file_paths)

# Create artifacts
out_filenames = []
for nc_file in nc_paths
    @info "Processing $nc_file"
    # Remove the word raw from the file name
    out_filename = replace(nc_file, r"_raw" => "")
    push!(out_filenames, out_filename)
    remove_time_dim_from_covers(nc_file, out_filename)
end

# Create directory and move artifacts
output_dir = basename(@__DIR__) * "_artifact"
if isdir(output_dir)
    @warn "$output_dir already exists. Content will end up in the artifact and may be overwritten."
    @warn "Abort this calculation, unless you know what you are doing."
else
    mkdir(output_dir)
end

for file_name in out_filenames
    Base.mv(file_name, joinpath(output_dir, file_name), force = true)
end

@info "Data files generated!"

create_artifact_guided(output_dir; artifact_name = basename(@__DIR__))

@info "You can now delete the files downloaded from ECMWF"
