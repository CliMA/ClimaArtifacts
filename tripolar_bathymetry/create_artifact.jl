# Generates the `tripolar_{one,half,quarter}_degree_bathymetry` artifacts: ETOPO bathymetry regridded
# onto the 360x180, 720x360 and 1440x720 tripolar grids that ClimaCoupler uses.
#
# Run with:
#   cd tripolar_bathymetry && julia --project=. create_artifact.jl [one] [half] [quarter]
#
# With no arguments, every resolution not yet in OutputArtifacts.toml is generated.

using NumericalEarth.Bathymetry: regrid_bathymetry
using Oceananigans
using NCDatasets
using ClimaArtifactsHelper
using Printf
using TOML

const resolutions = Dict(
    "one" => (; Nx = 360, Ny = 180),
    "half" => (; Nx = 720, Ny = 360),
    "quarter" => (; Nx = 1440, Ny = 720),
)

const output_root = get(ENV, "ARTIFACT_OUTPUT_DIR", @__DIR__)
const output_artifacts = "OutputArtifacts.toml"

const minimum_depth = 10
const major_basins = 2
const interpolation_passes = 10

const generation_vertical_size = 32
const generation_depth = 5500

"""
    write_bathymetry(resolution, Nx, Ny, artifact_name)

Regrid ETOPO onto the `Nx` x `Ny` tripolar grid and write it to `<artifact_name>_artifact/<artifact_name>.nc`.
Return the output directory.
"""
function write_bathymetry(resolution, Nx, Ny, artifact_name)
    output_directory = joinpath(output_root, artifact_name * "_artifact")
    output_path = joinpath(output_directory, artifact_name * ".nc")

    z = ExponentialDiscretization(generation_vertical_size, -generation_depth, 0; mutable = true)
    grid = TripolarGrid(CPU(); size = (Nx, Ny, generation_vertical_size), z, halo = (5, 5, 4))

    @info "Regridding ETOPO bathymetry onto the $resolution-degree tripolar grid (downloads ETOPO on first run)"

    bottom_field = regrid_bathymetry(
        grid;
        minimum_depth = minimum_depth,
        major_basins = major_basins,
        interpolation_passes = interpolation_passes,
    )

    bottom_height = collect(interior(bottom_field, :, :, 1))

    @assert size(bottom_height) == (Nx, Ny) "bottom_height is $(size(bottom_height)), expected ($Nx, $Ny)"
    @assert all(isfinite, bottom_height) "bottom_height contains non-finite values"

    ocean_points = filter(<(0), vec(bottom_height))
    @assert !isempty(ocean_points) "no ocean points found"

    mkpath(output_directory)
    isfile(output_path) && rm(output_path)

    NCDataset(output_path, "c") do ds
        defDim(ds, "x", Nx)
        defDim(ds, "y", Ny)

        ds.attrib["title"] = "ETOPO bathymetry regridded onto the $(Nx)x$(Ny) tripolar grid, for ClimaCoupler"
        ds.attrib["Nx"] = Nx
        ds.attrib["Ny"] = Ny
        ds.attrib["minimum_depth"] = minimum_depth
        ds.attrib["major_basins"] = major_basins
        ds.attrib["interpolation_passes"] = interpolation_passes
        ds.attrib["source_dataset"] = "NumericalEarth.DataWrangling.ETOPO.ETOPO2022"
        ds.attrib["note"] = "not snapped to vertical interfaces; GridFittedBottom does that at load time"

        bottom_variable = defVar(ds, "bottom_height", Float64, ("x", "y"))
        bottom_variable[:, :] = bottom_height
        bottom_variable.attrib["units"] = "m"
        bottom_variable.attrib["long_name"] = "bottom height, negative downwards, minor basins removed"
    end

    @info "Wrote $output_path ($(round(filesize(output_path) / 1024^2, digits = 1)) MiB)"

    @printf("ocean depth range: %.1f to %.1f m\n", extrema(ocean_points)...)
    @printf("land fraction:     %.3f\n", count(>=(0), bottom_height) / length(bottom_height))

    return output_directory
end

requested = isempty(ARGS) ? ["one", "half", "quarter"] : ARGS
unknown = setdiff(requested, keys(resolutions))
isempty(unknown) || error("unknown resolutions $unknown; choose from $(sort(collect(keys(resolutions))))")

for resolution in requested
    artifact_name = "tripolar_$(resolution)_degree_bathymetry"

    # Appending an entry that already exists would leave a duplicate key in OutputArtifacts.toml
    if isfile(output_artifacts) && haskey(TOML.parsefile(output_artifacts), artifact_name)
        @info "$artifact_name is already in $output_artifacts, skipping (delete its entry to regenerate it)"
        continue
    end

    (; Nx, Ny) = resolutions[resolution]
    output_directory = write_bathymetry(resolution, Nx, Ny, artifact_name)
    create_artifact_guided(output_directory; artifact_name, append = isfile(output_artifacts))
end
