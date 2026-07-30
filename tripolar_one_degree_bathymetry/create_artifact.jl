# Generates the `tripolar_one_degree_bathymetry` artifact: ETOPO bathymetry regridded onto the
# 360x180 tripolar grid that ClimaCoupler's `tripolar_ocean_simulation` uses.
#
# The regridding parameters below must match ClimaCoupler's `ext/ClimaCouplerCMIPExt/oceananigans.jl`
# exactly, since ClimaCoupler validates them against this artifact's attributes.
#
# Run with:
#   cd tripolar_one_degree_bathymetry && julia --project=. create_artifact.jl

using NumericalEarth.Bathymetry: regrid_bathymetry
using Oceananigans
using NCDatasets
using ClimaArtifactsHelper
using Printf

const artifact_name = basename(@__DIR__)
const output_directory = get(ENV, "ARTIFACT_OUTPUT_DIR", joinpath(@__DIR__, artifact_name * "_artifact"))
const output_path = joinpath(output_directory, "tripolar_one_degree_bathymetry.nc")

const Nx = 360
const Ny = 180
const minimum_depth = 10
const major_basins = 2
const interpolation_passes = 10

# The regridding is horizontal, so the vertical grid does not affect the result. These values match
# ClimaCoupler's defaults and are supplied only because TripolarGrid requires them.
const generation_vertical_size = 32
const generation_depth = 5500

z = ExponentialDiscretization(generation_vertical_size, -generation_depth, 0; mutable = true)
grid = TripolarGrid(CPU(); size = (Nx, Ny, generation_vertical_size), z, halo = (5, 5, 4))

@info "Regridding ETOPO bathymetry onto the one-degree tripolar grid (downloads ETOPO on first run)"

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

    ds.attrib["title"] = "ETOPO bathymetry regridded onto the 360x180 tripolar grid, for ClimaCoupler"
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

create_artifact_guided(output_directory; artifact_name)
