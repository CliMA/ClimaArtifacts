using ClimaArtifactsHelper
using NCDatasets

include("postprocess_artifact.jl")

# Source data directory
source_data_dir = "/net/sampo/data1/crujra/crujra_forcing_data"

# Get all directories that start with "crujra_2.5"
crujra_dirs = []
for item in readdir(source_data_dir)
    if startswith(item, "crujra_2.5_")
        push!(crujra_dirs, joinpath(source_data_dir, item))
    end
end
sort!(crujra_dirs)

# Make directory for artifact output
output_dir = basename(@__DIR__) * "_artifact"
if isdir(output_dir)
    @warn "$output_dir already exists. Content will end up in the artifact and may be overwritten."
    @warn "Abort this calculation, unless you know what you are doing."
else
    mkdir(output_dir)
end

# Check available disk space
completed_years = filter(x -> endswith(x, "_0.5x0.5.nc"), readdir(output_dir)) |> length
remaining_years = length(crujra_dirs) - completed_years
free_space_in_GB = diskstat().available / (1024^3) # convert from bytes to GB
# One year of CRUJRAv2.5 data at 0.5x0.5 degree resolution is approximately 2.9G
required_space_in_GB = 2.9 * remaining_years

if free_space_in_GB < required_space_in_GB
    @error "Insufficient space, free space: $free_space_in_GB GB and required space: $required_space_in_GB GB"
    exit(1)
end

println("Processing $(length(crujra_dirs)) years of CRUJRA data")
println("Completed years: $completed_years")
println("Remaining years: $remaining_years")
println("Free space: $(round(free_space_in_GB, digits=1)) GB")
println("Required space: $(round(required_space_in_GB, digits=1)) GB")
println()

# Process each directory
for dir in crujra_dirs
    year = last(basename(dir), 4)
    
    # Get all monthly .nc files for this year
    nc_paths = filter(f -> endswith(f, ".nc"), readdir(dir, join=true)) |> sort
    
    if isempty(nc_paths)
        @warn "No .nc files found in $dir, skipping"
        continue
    end
    
    # Output file path
    fileout = joinpath(output_dir, "crujra_forcing_data_$(year)_0.5x0.5.nc")
    
    if isfile(fileout)
        println("$fileout already exists; skipping")
        continue
    end
    
    println("Processing year $year: $(length(nc_paths)) monthly files")
    
    # Stitch all the months together
    mfds = NCDataset(nc_paths, aggdim="valid_time")
    
    postprocess_artifact(mfds, fileout)
    
    close(mfds)
    
    println("  ✓ Created $fileout")
end

println()
println("Creating artifact...")
create_artifact_guided(output_dir; artifact_name=basename(@__DIR__))
println("✓ Artifact creation complete!")
