# Generates the `orca_{one,half,quarter}_grid` artifacts: the eORCA1, eORCA05 and eORCA025 horizontal
# meshes and bathymetry, in a form ClimaCoupler can read.
#
# Run with:
#   cd orca_grid && julia --project=. create_artifact.jl [one] [half] [quarter]
#
# With no arguments, every resolution not yet in OutputArtifacts.toml is generated.

using NumericalEarth.Bathymetry: ORCAGrid, remove_minor_basins!, read_2d_nemo_variable, orient_xy
using NumericalEarth.DataWrangling: DataWrangling, Metadatum, dataset_variable_name
using NumericalEarth.DataWrangling.ORCA: ORCA, ORCADataset, ORCAOne, ORCAQuarter, default_south_rows_to_remove,
                                         periodic_overlap, north_fold_pivot
using Downloads: download
using Oceananigans
using Oceananigans.BoundaryConditions: FPivot
using Oceananigans.Grids: topology
using NCDatasets
using ClimaArtifactsHelper
using Printf
using TOML

# NumericalEarth has no half-degree ORCA dataset, so `ORCAHalf` extends its ORCA interface here. The
# source is the eORCA05.L75 `domain_cfg` of Zenodo record 13385024, which holds both the staggered
# mesh and the bathymetry. The file's `jperio = 6` marks an F-point north fold, as in eORCA1. Its
# first 78 rows are land; removing 68 leaves a 10-row land margin, the same latitude span as the
# 5-row margin NumericalEarth leaves on the eORCA1 grid.
struct ORCAHalf <: ORCADataset end

const domain_cfg_url = "https://zenodo.org/records/13385024/files/eORCA05.L75_domain_cfg.nc"
const ORCAHalf_variable_names = Dict(:bottom_height => "bathy_meter", :mesh_mask => "glamt")

ORCA.mesh_mask_url(::ORCAHalf) = domain_cfg_url
ORCA.bathymetry_url(::ORCAHalf) = domain_cfg_url
ORCA.north_fold_pivot(::ORCAHalf) = FPivot
ORCA.default_south_rows_to_remove(::ORCAHalf) = 68
DataWrangling.dataset_variable_name(metadatum::Metadatum{<:ORCAHalf}) =
    ORCAHalf_variable_names[metadatum.name]

const resolutions = Dict(
    "one" => (;
        dataset = ORCAOne(),
        label = "eORCA1",
        title = "eORCA1 (ORCAOne) horizontal mesh and bathymetry for ClimaCoupler",
        source_dataset = "NumericalEarth.DataWrangling.ORCA.ORCAOne",
        source_record = "https://zenodo.org/records/4436658",
        download_size = "~1 GB",
    ),
    "half" => (;
        dataset = ORCAHalf(),
        label = "eORCA05",
        title = "eORCA05 (eORCA05.L75) horizontal mesh and bathymetry for ClimaCoupler",
        source_dataset = "eORCA05.L75_domain_cfg.nc, read through NumericalEarth.Bathymetry.ORCAGrid",
        source_record = "https://zenodo.org/records/13385024",
        download_size = "~90 MB",
    ),
    "quarter" => (;
        dataset = ORCAQuarter(),
        label = "eORCA025",
        title = "eORCA025 (ORCAQuarter) horizontal mesh and bathymetry for ClimaCoupler",
        source_dataset = "NumericalEarth.DataWrangling.ORCA.ORCAQuarter",
        source_record = "https://zenodo.org/records/15494369",
        download_size = "~50 MB",
    ),
)

const output_root = get(ENV, "ARTIFACT_OUTPUT_DIR", @__DIR__)
const output_artifacts = "OutputArtifacts.toml"

# Only the horizontal mesh is stored, so these vertical settings affect nothing that is written; they
# are supplied because ORCAGrid requires them.
const generation_vertical_size = 60
const generation_vertical_domain = (-6000, 0)
const major_basins = 2

# The metric arrays carry Unicode sub/superscripts that do not survive NetCDF portably, so each is
# written under an ASCII name. Suffix letters denote the stagger position: c = Center, f = Face, in
# (x, y) order, with the trailing `a` marking the vertically-averaged (Nothing) location.
#
# The stagger location matters for the array extent, which `metric_extent` takes from the fold
# topology: under RightFaceFolded a Face-in-y metric has Ny+1 rows, one more than a Center-in-y one,
# and the extra row is the fold row, which `fill_halo_regions!` cannot reconstruct.
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
    orca_bottom_height(grid, orca_dataset)

The `orca_dataset` bottom height on `grid`, with minor basins removed.

This mirrors the bathymetry block of `NumericalEarth.Bathymetry.ORCAGrid` but stops short of
`GridFittedBottom`, which would snap the bottom onto the generation-time vertical interfaces and
clamp it to the generation-time depth. Storing the unsnapped field lets ClimaCoupler snap and clamp
against the vertical grid it actually runs with. Land carries the sentinel `100`, as upstream.
"""
function orca_bottom_height(grid, orca_dataset)
    metadatum = Metadatum(:bottom_height; dataset = orca_dataset)
    path = download(metadatum)

    dataset = Dataset(path)
    variable_name = dataset_variable_name(metadatum)
    data = read_2d_nemo_variable(dataset, variable_name)
    close(dataset)

    data = orient_xy(data, size(data)...; name = string(variable_name))

    # The first kept column `ic + 1` matches ORCAGrid, which aligns NEMO's fold mirror with the
    # Oceananigans one: column 2 for an F pivot, column 3 for a T pivot.
    overlap = periodic_overlap(orca_dataset)
    ic = north_fold_pivot(orca_dataset) === FPivot ? 1 : 2
    southern_rows_removed = default_south_rows_to_remove(orca_dataset)
    data = data[ic+1:ic+size(data, 1)-overlap, southern_rows_removed+1:end-1]

    bottom_height = Float64.(coalesce.(data, 0.0))
    bottom_height .= ifelse.(isfinite.(bottom_height) .& (bottom_height .> 0), .-bottom_height, 100.0)

    bottom_field = Field{Center, Center, Nothing}(grid)
    set!(bottom_field, bottom_height)
    remove_minor_basins!(bottom_field, major_basins)

    return collect(interior(bottom_field, :, :, 1))
end

"""
    write_orca_grid(source, artifact_name)

Build the ORCA mesh described by `source` and write it to `<artifact_name>/<artifact_name>.nc`.
Return the output directory.
"""
function write_orca_grid(source, artifact_name)
    (; dataset, label) = source
    output_directory = joinpath(output_root, artifact_name)
    output_path = joinpath(output_directory, artifact_name * ".nc")

    @info "Building the $label mesh with NumericalEarth (downloads $(source.download_size) from $(source.source_record) on first run)"

    grid = ORCAGrid(
        CPU(),
        Float64;
        dataset,
        Nz = generation_vertical_size,
        z = generation_vertical_domain,
        with_bathymetry = false,
    )

    conformal_mapping = grid.conformal_mapping
    Nx, Ny = grid.Nx, grid.Ny
    @info "$label mesh reconstructed" Nx Ny radius = grid.radius

    bottom_height = orca_bottom_height(grid, dataset)

    @assert size(bottom_height) == (Nx, Ny) "bottom_height is $(size(bottom_height)), expected ($Nx, $Ny)"
    @assert all(isfinite, bottom_height) "bottom_height contains non-finite values"

    mkpath(output_directory)
    isfile(output_path) && rm(output_path)

    Nx_face, Ny_face = metric_extent(grid, Face, Face)
    fold_topology_name = north_fold_pivot(dataset) === FPivot ? "RightFaceFolded" : "RightCenterFolded"

    NCDataset(output_path, "c") do ds
        defDim(ds, "x", Nx)
        defDim(ds, "y", Ny)
        defDim(ds, "x_face", Nx_face)
        defDim(ds, "y_face", Ny_face)

        ds.attrib["title"] = source.title
        ds.attrib["Nx"] = Nx
        ds.attrib["Ny"] = Ny
        ds.attrib["radius"] = grid.radius
        ds.attrib["north_poles_latitude"] = conformal_mapping.north_poles_latitude
        ds.attrib["first_pole_longitude"] = conformal_mapping.first_pole_longitude
        ds.attrib["southernmost_latitude"] = conformal_mapping.southernmost_latitude
        ds.attrib["major_basins"] = major_basins
        ds.attrib["topology"] = "Periodic, $(fold_topology_name), Bounded"
        ds.attrib["north_fold_pivot"] = string(nameof(north_fold_pivot(dataset)))
        ds.attrib["source_dataset"] = source.source_dataset
        ds.attrib["source_record"] = source.source_record
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

    return output_directory
end

requested = isempty(ARGS) ? ["one", "half", "quarter"] : ARGS
unknown = setdiff(requested, keys(resolutions))
isempty(unknown) || error("unknown resolutions $unknown; choose from $(sort(collect(keys(resolutions))))")

for resolution in requested
    artifact_name = "orca_$(resolution)_grid"

    # Appending an entry that already exists would leave a duplicate key in OutputArtifacts.toml
    if isfile(output_artifacts) && haskey(TOML.parsefile(output_artifacts), artifact_name)
        @info "$artifact_name is already in $output_artifacts, skipping (delete its entry to regenerate it)"
        continue
    end

    output_directory = write_orca_grid(resolutions[resolution], artifact_name)
    create_artifact_guided(output_directory; artifact_name, append = isfile(output_artifacts))
end
