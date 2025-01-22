using ClimaArtifactsHelper
using NCDatasets
import OrderedCollections: OrderedDict

include("postprocess_artifact.jl")
include("postprocess_and_make_weekly_lai_data.jl")
include("combine_rate_and_inst.jl")
include("thin_and_postprocess_artifact.jl")

# Get all directories that start with "era_5"
era_5_dirs = []
for (_, dirs, _) in walkdir(".")
    for dir in dirs
        if startswith(dir, "era_5")
            push!(era_5_dirs, dir)
        end
    end
end

# Make directories for artifacts
output_dir = basename(@__DIR__) * "_artifact"
if isdir(output_dir)
    @warn "$output_dir already exists. Content will end up in the artifact and may be overwritten."
    @warn "Abort this calculation, unless you know what you are doing."
else
    mkdir(output_dir)
end

output_dir_lai = basename(@__DIR__) * "_lai"
if isdir(output_dir_lai)
    @warn "$output_dir_lai already exists. Content will end up in the artifact and may be overwritten."
    @warn "Abort this calculation, unless you know what you are doing."
else
    mkdir(output_dir_lai)
end

if length(ARGS) != 1
    return error("Usage: julia --project=. create_artifact.jl res where res is the resolution of the data downloaded")
end
res = ARGS[1]
completed_years = filter(x -> endswith(x, "_$(res)x$(res).nc"), readdir(output_dir)) |> length
remaining_years = length(era_5_dirs) - completed_years
free_space_in_GB = diskstat().available / (1024^3) # convert from bytes to GB
# One year of non-LAI data with a resolution of 1.0 by 1.0 is approximately 22G
required_space_in_GB = 22 * (1 / (parse(Float64, res))^2) * remaining_years

if free_space_in_GB < required_space_in_GB
    print("Insufficient space, free space: $free_space_in_GB GB and required space: $required_space_in_GB GB")
end

# Process each directory
for dir in era_5_dirs
    year = last(dir, 4)
    file_paths = readdir(dir, join = true)

    # Process *_rate.nc and *_inst.nc files and stitch them as a single file
    rate_file_paths =
        filter(file_path -> endswith(file_path, "rate.nc"), file_paths) |> sort
    inst_file_paths =
        filter(file_path -> endswith(file_path, "inst.nc"), file_paths) |> sort
    for (rate_file_path, inst_file_path) in zip(rate_file_paths, inst_file_paths)
        output_filepath = chop(rate_file_path, tail = 8) * ".nc"
        isfile(output_filepath) && continue
        combine_rate_and_inst(output_filepath, rate_file_path, inst_file_path)
    end

    # Filter to get only .nc files for monthly data
    file_paths = readdir(dir, join = true)
    nc_paths =
        filter(file_path -> endswith(file_path, ".nc"), file_paths) |>
        filter(file_path -> !(file_path in rate_file_paths)) |>
        filter(file_path -> !(file_path in inst_file_paths)) |>
        sort!

    # Stitch all the months together and make the forcing data for each year as individual
    # files
    mfds = NCDataset(nc_paths, aggdim = "valid_time")

    fileout = joinpath(output_dir, "era5_$(year)_$(res)x$(res).nc")
    if isfile(fileout)
        println("$fileout already exists; skipping the creation of this file")
    else
        println("Processing $fileout")
        thin_and_postprocess_artifact(mfds, fileout)
    end

    fileout_lai = joinpath(output_dir_lai, "era5_$(year)_$(res)x$(res)_lai.nc")
    if isfile(fileout_lai)
        println("$fileout_lai already exists; skipping the creation of this file")
    else
        println("Processing $fileout_lai")
        postprocess_and_make_weekly_lai_data(mfds, fileout_lai)
    end
    close(mfds)
end

create_artifact_guided(output_dir; artifact_name = basename(@__DIR__))
create_artifact_guided(
    output_dir_lai;
    artifact_name = basename(@__DIR__) * "_lai",
    append = true,
)
