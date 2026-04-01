using ClimaArtifactsHelper

# The raw data files (era5_lake_cover.nc and era5_lake_depth.nc) must be
# downloaded from the CDS API before running this script.
# See get_era5_lake_cover_and_depth.py and the README for instructions.

const FILE_NAMES = ["era5_lake_cover.nc", "era5_lake_depth.nc"]

output_dir = basename(@__DIR__) * "_artifact"
if isdir(output_dir)
    @warn "$output_dir already exists. Content will end up in the artifact and may be overwritten."
    @warn "Abort this calculation, unless you know what you are doing."
else
    mkdir(output_dir)
end

for file_name in FILE_NAMES
    if !isfile(file_name)
        error("$file_name not found. Download it first using get_era5_lake_cover_and_depth.py")
    end
    Base.cp(file_name, joinpath(output_dir, file_name), force = true)
end

@info "Data files copied!"

create_artifact_guided(output_dir; artifact_name = basename(@__DIR__))
