# Generates the `en4_ocean_initial_conditions_2010_01` artifact: EN4 monthly temperature and salinity
# for January 2010, inpainted, on EN4's native longitude-latitude-depth grid.
#
# The fields are stored on the native grid rather than on a model grid, so that one artifact serves
# every ocean grid ClimaCoupler runs on. Because inpainting has already filled the land, ClimaCoupler
# only has to interpolate.
#
# Run with:
#   cd en4_ocean_initial_conditions_2010_01 && julia --project=. create_artifact.jl

using NumericalEarth.DataWrangling: Metadatum, default_inpainting
using NumericalEarth.DataWrangling.EN4: EN4Monthly
using Oceananigans
using Oceananigans.Grids: λnodes, φnodes, znodes, topology
using NCDatasets
using ClimaArtifactsHelper
using Dates
using Printf

const start_date = DateTime(2010, 1, 1)
const artifact_name = basename(@__DIR__)
const output_directory = get(ENV, "ARTIFACT_OUTPUT_DIR", joinpath(@__DIR__, artifact_name * "_artifact"))
const output_path = joinpath(output_directory, "en4_ocean_initial_conditions_2010_01.nc")

const temperature_bounds = (-5.0, 45.0)
const salinity_bounds = (0.0, 50.0)

temperature_metadatum = Metadatum(:temperature; date = start_date, dataset = EN4Monthly())
salinity_metadatum = Metadatum(:salinity; date = start_date, dataset = EN4Monthly())

@info "Building inpainted EN4 fields on the native grid (downloads and inpaints on first run)"

temperature_field = Field(temperature_metadatum, CPU())
salinity_field = Field(salinity_metadatum, CPU())

grid = temperature_field.grid

temperature = collect(interior(temperature_field))
salinity = collect(interior(salinity_field))

Nx, Ny, Nz = size(temperature)
@info "EN4 native grid" Nx Ny Nz

longitude = collect(λnodes(grid, Center()))
latitude = collect(φnodes(grid, Center()))
z = collect(znodes(grid, Center()))

closed_interfaces(faces, N, period) =
    length(faces) == N + 1 ? collect(faces) : vcat(collect(faces), faces[1] + period)

longitude_interfaces = closed_interfaces(λnodes(grid, Face()), Nx, 360)
latitude_interfaces = closed_interfaces(φnodes(grid, Face()), Ny, 180)
z_interfaces = collect(znodes(grid, Face()))

@assert length(longitude_interfaces) == Nx + 1
@assert length(latitude_interfaces) == Ny + 1
@assert length(z_interfaces) == Nz + 1

@assert size(salinity) == (Nx, Ny, Nz) "salinity is $(size(salinity)), expected $((Nx, Ny, Nz))"
@assert length(longitude) == Nx && length(latitude) == Ny && length(z) == Nz

@assert !any(isnan, temperature) "temperature still has NaNs after inpainting"
@assert !any(isnan, salinity) "salinity still has NaNs after inpainting"
@assert all(isfinite, temperature) "temperature has non-finite values"
@assert all(isfinite, salinity) "salinity has non-finite values"

temperature_range = extrema(temperature)
salinity_range = extrema(salinity)

@assert temperature_bounds[1] <= temperature_range[1] && temperature_range[2] <= temperature_bounds[2] "temperature range $temperature_range outside $temperature_bounds"
@assert salinity_bounds[1] <= salinity_range[1] && salinity_range[2] <= salinity_bounds[2] "salinity range $salinity_range outside $salinity_bounds"

inpainting = default_inpainting(temperature_metadatum)

mkpath(output_directory)
isfile(output_path) && rm(output_path)

NCDataset(output_path, "c") do ds
    defDim(ds, "longitude", Nx)
    defDim(ds, "latitude", Ny)
    defDim(ds, "z", Nz)
    defDim(ds, "longitude_interface", Nx + 1)
    defDim(ds, "latitude_interface", Ny + 1)
    defDim(ds, "z_interface", Nz + 1)

    ds.attrib["title"] = "EN4 monthly temperature and salinity, January 2010, inpainted, native grid"
    ds.attrib["date"] = string(start_date)
    ds.attrib["source_dataset"] = "NumericalEarth.DataWrangling.EN4.EN4Monthly"
    ds.attrib["inpainting"] = string(inpainting)
    ds.attrib["inpainting_maxiter"] = string(getproperty(inpainting, :maxiter))
    ds.attrib["note"] = "land is filled by inpainting; no missing values remain"
    ds.attrib["topology"] = string(topology(grid))

    longitude_variable = defVar(ds, "longitude", Float64, ("longitude",))
    longitude_variable[:] = longitude
    longitude_variable.attrib["units"] = "degrees_east"

    latitude_variable = defVar(ds, "latitude", Float64, ("latitude",))
    latitude_variable[:] = latitude
    latitude_variable.attrib["units"] = "degrees_north"

    z_variable = defVar(ds, "z", Float64, ("z",))
    z_variable[:] = z
    z_variable.attrib["units"] = "m"
    z_variable.attrib["positive"] = "up"

    longitude_interface_variable = defVar(ds, "longitude_interfaces", Float64, ("longitude_interface",))
    longitude_interface_variable[:] = longitude_interfaces
    longitude_interface_variable.attrib["units"] = "degrees_east"

    latitude_interface_variable = defVar(ds, "latitude_interfaces", Float64, ("latitude_interface",))
    latitude_interface_variable[:] = latitude_interfaces
    latitude_interface_variable.attrib["units"] = "degrees_north"

    z_interface_variable = defVar(ds, "z_interfaces", Float64, ("z_interface",))
    z_interface_variable[:] = z_interfaces
    z_interface_variable.attrib["units"] = "m"
    z_interface_variable.attrib["positive"] = "up"

    temperature_variable = defVar(ds, "temperature", Float64, ("longitude", "latitude", "z"))
    temperature_variable[:, :, :] = temperature
    temperature_variable.attrib["units"] = "degC"

    salinity_variable = defVar(ds, "salinity", Float64, ("longitude", "latitude", "z"))
    salinity_variable[:, :, :] = salinity
    salinity_variable.attrib["units"] = "g/kg"
end

@info "Wrote $output_path ($(round(filesize(output_path) / 1024^2, digits = 1)) MiB)"

@printf("temperature range: %.2f to %.2f degC\n", temperature_range...)
@printf("salinity range:    %.2f to %.2f g/kg\n", salinity_range...)
@printf("longitude range:   %.2f to %.2f\n", extrema(longitude)...)
@printf("latitude range:    %.2f to %.2f\n", extrema(latitude)...)
@printf("z range:           %.1f to %.1f m\n", extrema(z)...)

create_artifact_guided(output_directory; artifact_name)
