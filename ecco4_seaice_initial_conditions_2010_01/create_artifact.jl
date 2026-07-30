# Generates the `ecco4_seaice_initial_conditions_2010_01` artifact: ECCO4 monthly sea-ice
# concentration and thickness for January 2010, inpainted, on ECCO4's native longitude-latitude grid.
#
# The raw fields come from the already-published `ecco4_SIarea_SIheff_2010_01` artifact, so no ECCO
# credentials are needed here or anywhere downstream.
#
# Run with:
#   cd ecco4_seaice_initial_conditions_2010_01 && julia --project=. create_artifact.jl

using NumericalEarth.DataWrangling: Metadatum, default_inpainting
using NumericalEarth.DataWrangling.ECCO: ECCO4Monthly
using Oceananigans
using Oceananigans.Grids: λnodes, φnodes, topology
using NCDatasets
using ClimaArtifactsHelper
using Dates
using Printf
import Pkg, Artifacts

const start_date = DateTime(2010, 1, 1)
const artifact_name = basename(@__DIR__)
const output_directory = get(ENV, "ARTIFACT_OUTPUT_DIR", joinpath(@__DIR__, artifact_name * "_artifact"))
const output_path = joinpath(output_directory, "ecco4_seaice_initial_conditions_2010_01.nc")

# The raw January 2010 ECCO files are already published as the `ecco4_SIarea_SIheff_2010_01`
# artifact. Sourcing them from there rather than from ecco.jpl.nasa.gov keeps this script runnable
# without ECCO credentials or access to JPL, which is not reachable from all networks.
const source_artifact = "ecco4_SIarea_SIheff_2010_01"
const source_artifacts_toml = normpath(joinpath(@__DIR__, "..", source_artifact, "OutputArtifacts.toml"))

function source_directory()
    downloadable = Artifacts.select_downloadable_artifacts(source_artifacts_toml)
    Pkg.Artifacts.ensure_artifact_installed(
        source_artifact,
        downloadable[source_artifact],
        source_artifacts_toml,
    )
    hash = Artifacts.artifact_hash(source_artifact, source_artifacts_toml)
    return Artifacts.artifact_path(hash)
end

const source_data_directory = source_directory()
@info "Reading raw ECCO4 files from $source_artifact" source_data_directory

concentration_metadatum =
    Metadatum(:sea_ice_concentration; date = start_date, dataset = ECCO4Monthly(), dir = source_data_directory)
thickness_metadatum =
    Metadatum(:sea_ice_thickness; date = start_date, dataset = ECCO4Monthly(), dir = source_data_directory)

@info "Building inpainted ECCO4 sea-ice fields on the native grid (downloads and inpaints on first run)"

concentration_field = Field(concentration_metadatum, CPU())
thickness_field = Field(thickness_metadatum, CPU())

grid = concentration_field.grid

concentration = collect(interior(concentration_field, :, :, 1))
thickness = collect(interior(thickness_field, :, :, 1))

Nx, Ny = size(concentration)
@info "ECCO4 native grid" Nx Ny

longitude = collect(λnodes(grid, Center()))
latitude = collect(φnodes(grid, Center()))

closed_interfaces(faces, N, period) =
    length(faces) == N + 1 ? collect(faces) : vcat(collect(faces), faces[1] + period)

longitude_interfaces = closed_interfaces(λnodes(grid, Face()), Nx, 360)
latitude_interfaces = closed_interfaces(φnodes(grid, Face()), Ny, 180)

@assert length(longitude_interfaces) == Nx + 1
@assert length(latitude_interfaces) == Ny + 1

@assert size(thickness) == (Nx, Ny) "thickness is $(size(thickness)), expected $((Nx, Ny))"
@assert length(longitude) == Nx && length(latitude) == Ny

@assert !any(isnan, concentration) "concentration has NaNs"
@assert !any(isnan, thickness) "thickness has NaNs"

concentration_range = extrema(concentration)
thickness_range = extrema(thickness)

@assert 0 <= concentration_range[1] && concentration_range[2] <= 1 "concentration range $concentration_range outside [0, 1]"
@assert 0 <= thickness_range[1] "thickness range $thickness_range reaches below zero"

inpainting = default_inpainting(concentration_metadatum)

mkpath(output_directory)
isfile(output_path) && rm(output_path)

NCDataset(output_path, "c") do ds
    defDim(ds, "longitude", Nx)
    defDim(ds, "latitude", Ny)
    defDim(ds, "longitude_interface", Nx + 1)
    defDim(ds, "latitude_interface", Ny + 1)

    ds.attrib["title"] = "ECCO4 monthly sea-ice concentration and thickness, January 2010, native grid"
    ds.attrib["date"] = string(start_date)
    ds.attrib["source_dataset"] = "NumericalEarth.DataWrangling.ECCO.ECCO4Monthly"
    ds.attrib["inpainting"] = string(inpainting)
    ds.attrib["note"] = "written as ECCO4 reports it, with land carrying 0"
    ds.attrib["concentration_range"] = collect(concentration_range)
    ds.attrib["thickness_range"] = collect(thickness_range)
    ds.attrib["topology"] = string(topology(grid))

    longitude_variable = defVar(ds, "longitude", Float64, ("longitude",))
    longitude_variable[:] = longitude
    longitude_variable.attrib["units"] = "degrees_east"

    latitude_variable = defVar(ds, "latitude", Float64, ("latitude",))
    latitude_variable[:] = latitude
    latitude_variable.attrib["units"] = "degrees_north"

    longitude_interface_variable = defVar(ds, "longitude_interfaces", Float64, ("longitude_interface",))
    longitude_interface_variable[:] = longitude_interfaces
    longitude_interface_variable.attrib["units"] = "degrees_east"

    latitude_interface_variable = defVar(ds, "latitude_interfaces", Float64, ("latitude_interface",))
    latitude_interface_variable[:] = latitude_interfaces
    latitude_interface_variable.attrib["units"] = "degrees_north"

    concentration_variable = defVar(ds, "sea_ice_concentration", Float64, ("longitude", "latitude"))
    concentration_variable[:, :] = concentration
    concentration_variable.attrib["units"] = "1"

    thickness_variable = defVar(ds, "sea_ice_thickness", Float64, ("longitude", "latitude"))
    thickness_variable[:, :] = thickness
    thickness_variable.attrib["units"] = "m"
end

@info "Wrote $output_path ($(round(filesize(output_path) / 1024^2, digits = 1)) MiB)"

@printf("concentration range:        %.6f to %.6f\n", concentration_range...)
@printf("thickness range:            %.6f to %.6f m\n", thickness_range...)
@printf("ice-covered fraction (>1%%): %.4f\n", count(>(0.01), concentration) / length(concentration))

create_artifact_guided(output_directory; artifact_name)
