# Generates the `orca_one_grid` artifact: the eORCA1 horizontal mesh and bathymetry, in a form
# ClimaCoupler can read without NumericalEarth.
#
# Run with:
#   cd orca_one_grid && julia --project=. create_artifact.jl

using NumericalEarth.Bathymetry: ORCAGrid, remove_minor_basins!, read_2d_nemo_variable, orient_xy
using NumericalEarth.DataWrangling: Metadatum, dataset_variable_name
using NumericalEarth.DataWrangling.ORCA: ORCAOne, default_south_rows_to_remove
using Downloads: download
using Oceananigans
using Oceananigans.Grids: topology
using NCDatasets
using ClimaArtifactsHelper
using Printf

const artifact_name = basename(@__DIR__)
const output_directory = get(ENV, "ARTIFACT_OUTPUT_DIR", joinpath(@__DIR__, artifact_name * "_artifact"))
const output_path = joinpath(output_directory, "orca_one_grid.nc")

# Only the horizontal mesh is stored, so these vertical settings affect nothing that is written; they
# are supplied because ORCAGrid requires them.
const generation_vertical_size = 60
const generation_vertical_domain = (-6000, 0)
const major_basins = 2

# The metric arrays carry Unicode sub/superscripts that do not survive NetCDF portably, so each is
# written under an ASCII name. Suffix letters denote the stagger position: c = Center, f = Face, in
# (x, y) order, with the trailing `a` marking the vertically-averaged (Nothing) location.
#
# The stagger location matters for the array extent: under the (Periodic, RightFaceFolded) topology a
# Face-in-y metric has Ny+1 rows, one more than a Center-in-y one. Storing only Ny rows would drop the
# fold row, which `fill_halo_regions!` cannot reconstruct.
const metric_names = (
    (:λᶜᶜᵃ, "lambda_cca", Center, Center),  (:λᶠᶜᵃ, "lambda_fca", Face, Center),
    (:λᶜᶠᵃ, "lambda_cfa", Center, Face),    (:λᶠᶠᵃ, "lambda_ffa", Face, Face),
    (:φᶜᶜᵃ, "phi_cca",    Center, Center),  (:φᶠᶜᵃ, "phi_fca",    Face, Center),
    (:φᶜᶠᵃ, "phi_cfa",    Center, Face),    (:φᶠᶠᵃ, "phi_ffa",    Face, Face),
    (:Δxᶜᶜᵃ, "dx_cca",    Center, Center),  (:Δxᶠᶜᵃ, "dx_fca",    Face, Center),
    (:Δxᶜᶠᵃ, "dx_cfa",    Center, Face),    (:Δxᶠᶠᵃ, "dx_ffa",    Face, Face),
    (:Δyᶜᶜᵃ, "dy_cca",    Center, Center),  (:Δyᶠᶜᵃ, "dy_fca",    Face, Center),
    (:Δyᶜᶠᵃ, "dy_cfa",    Center, Face),    (:Δyᶠᶠᵃ, "dy_ffa",    Face, Face),
    (:Azᶜᶜᵃ, "area_cca",  Center, Center),  (:Azᶠᶜᵃ, "area_fca",  Face, Center),
    (:Azᶜᶠᵃ, "area_cfa",  Center, Face),    (:Azᶠᶠᵃ, "area_ffa",  Face, Face),
)

"""
    metric_extent(grid, LX, LY)

Interior extent of a metric at stagger location `(LX, LY)`, following the grid's topology.
"""
function metric_extent(grid, LX, LY)
    TX, TY, _ = topology(grid)
    return Base.length(LX(), TX(), grid.Nx), Base.length(LY(), TY(), grid.Ny)
end

"""
    interior_metric(grid, name, LX, LY)

The interior part of a grid metric, with halos discarded. Halos are regenerated at load time by
`fill_halo_regions!`, so storing them would only freeze the halo size.
"""
function interior_metric(grid, name, LX, LY)
    metric = getproperty(grid, name)
    Ni, Nj = metric_extent(grid, LX, LY)
    return collect(metric[1:Ni, 1:Nj])
end

"""
    orca_bottom_height(grid)

The eORCA1 bottom height on `grid`, with minor basins removed.

This mirrors the bathymetry block of `NumericalEarth.Bathymetry.ORCAGrid` but stops short of
`GridFittedBottom`, which would snap the bottom onto the generation-time vertical interfaces and
clamp it to the generation-time depth. Storing the unsnapped field lets ClimaCoupler snap and clamp
against the vertical grid it actually runs with. Land carries the sentinel `100`, as upstream.
"""
function orca_bottom_height(grid)
    metadatum = Metadatum(:bottom_height; dataset = ORCAOne())
    path = download(metadatum)

    dataset = Dataset(path)
    variable_name = dataset_variable_name(metadatum)
    data = read_2d_nemo_variable(dataset, variable_name)
    close(dataset)

    data = orient_xy(data, size(data)...; name = string(variable_name))

    southern_rows_removed = default_south_rows_to_remove(ORCAOne())
    if southern_rows_removed > 0
        data = data[:, southern_rows_removed+1:end]
    end

    bottom_height = Float64.(coalesce.(data, 0.0))
    bottom_height .= ifelse.(isfinite.(bottom_height) .& (bottom_height .> 0), .-bottom_height, 100.0)

    bottom_field = Field{Center, Center, Nothing}(grid)
    set!(bottom_field, bottom_height)
    remove_minor_basins!(bottom_field, major_basins)

    return collect(interior(bottom_field, :, :, 1))
end

@info "Building the eORCA1 mesh with NumericalEarth (downloads ~1 GB from Zenodo record 4436658 on first run)"

grid = ORCAGrid(
    CPU(),
    Float64;
    dataset = ORCAOne(),
    Nz = generation_vertical_size,
    z = generation_vertical_domain,
    with_bathymetry = false,
)

conformal_mapping = grid.conformal_mapping
Nx, Ny = grid.Nx, grid.Ny
@info "eORCA1 mesh reconstructed" Nx Ny radius = grid.radius

bottom_height = orca_bottom_height(grid)

@assert size(bottom_height) == (Nx, Ny) "bottom_height is $(size(bottom_height)), expected ($Nx, $Ny)"
@assert all(isfinite, bottom_height) "bottom_height contains non-finite values"

mkpath(output_directory)
isfile(output_path) && rm(output_path)

Nx_face, Ny_face = metric_extent(grid, Face, Face)

NCDataset(output_path, "c") do ds
    defDim(ds, "x", Nx)
    defDim(ds, "y", Ny)
    defDim(ds, "x_face", Nx_face)
    defDim(ds, "y_face", Ny_face)

    ds.attrib["title"] = "eORCA1 (ORCAOne) horizontal mesh and bathymetry for ClimaCoupler"
    ds.attrib["Nx"] = Nx
    ds.attrib["Ny"] = Ny
    ds.attrib["radius"] = grid.radius
    ds.attrib["north_poles_latitude"] = conformal_mapping.north_poles_latitude
    ds.attrib["first_pole_longitude"] = conformal_mapping.first_pole_longitude
    ds.attrib["southernmost_latitude"] = conformal_mapping.southernmost_latitude
    ds.attrib["major_basins"] = major_basins
    ds.attrib["topology"] = "Periodic, RightFaceFolded, Bounded"
    ds.attrib["source_dataset"] = "NumericalEarth.DataWrangling.ORCA.ORCAOne"
    ds.attrib["source_record"] = "https://zenodo.org/records/4436658"
    ds.attrib["halos"] = "not stored; fill with Oceananigans.BoundaryConditions.fill_halo_regions!"

    for (symbol, variable_name, LX, LY) in metric_names
        data = interior_metric(grid, symbol, LX, LY)
        @assert all(isfinite, data) "$symbol contains non-finite values"

        x_dimension = LX === Face && Nx_face != Nx ? "x_face" : "x"
        y_dimension = LY === Face && Ny_face != Ny ? "y_face" : "y"

        variable = defVar(ds, variable_name, Float64, (x_dimension, y_dimension))
        variable[:, :] = data
        variable.attrib["oceananigans_name"] = string(symbol)
        variable.attrib["location"] = "$(LX), $(LY)"
    end

    bottom_variable = defVar(ds, "bottom_height", Float64, ("x", "y"))
    bottom_variable[:, :] = bottom_height
    bottom_variable.attrib["units"] = "m"
    bottom_variable.attrib["long_name"] = "bottom height, negative downwards, minor basins removed"
    bottom_variable.attrib["land_value"] = 100.0
    bottom_variable.attrib["note"] = "not snapped to vertical interfaces; GridFittedBottom does that at load time"
end

@info "Wrote $output_path ($(round(filesize(output_path) / 1024^2, digits = 1)) MiB)"

ocean_points = filter(<(0), vec(bottom_height))
@printf("ocean depth range: %.1f to %.1f m\n", extrema(ocean_points)...)
@printf("land fraction:     %.3f\n", count(>=(0), bottom_height) / length(bottom_height))

create_artifact_guided(output_directory; artifact_name)
