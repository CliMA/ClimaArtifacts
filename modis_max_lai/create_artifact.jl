# MODIS maximum LAI (2000-2020): for each cell, the maximum over all months of
# the land-fraction corrected yearly files of the `modis_lai` artifact.

using Artifacts
using NCDatasets

using ClimaArtifactsHelper

const OUTPUT_DIR = basename(@__DIR__) * "_artifact"
const OUTPUT_FILE = "modis_max_lai.nc"
const YEARS = 2000:2020

if isdir(OUTPUT_DIR)
    @warn "$OUTPUT_DIR already exists. Content will end up in the artifact and may be overwritten."
    @warn "Abort this calculation, unless you know what you are doing."
else
    mkdir(OUTPUT_DIR)
end

files = [joinpath(artifact"modis_lai", "Yuan_et_al_$(year)_1x1.nc") for year in YEARS]
lon, lat, fland = NCDataset(first(files)) do ds
    ds["lon"][:], ds["lat"][:], ds["land_fraction"][:, :]
end
max_lai = fill(-Inf32, length(lon), length(lat))
for file in files
    NCDataset(file) do ds
        @assert ds["lon"][:] == lon && ds["lat"][:] == lat
        @assert ds["land_fraction"][:, :] == fland
        max_lai .= max.(max_lai, dropdims(maximum(ds["lai"][:, :, :]; dims = 3); dims = 3))
    end
end

NCDataset(joinpath(OUTPUT_DIR, OUTPUT_FILE), "c") do ds
    defDim(ds, "lon", length(lon))
    defDim(ds, "lat", length(lat))

    ds.attrib["title"] = "MODIS maximum LAI ($(first(YEARS))-$(last(YEARS))), land-fraction corrected"
    ds.attrib["source"] = "Maximum over all months of the yearly files of the modis_lai artifact"
    ds.attrib["history"] = "Created by CliMA (see modis_max_lai folder in ClimaArtifacts)"

    lo = defVar(ds, "lon", Float32, ("lon",))
    lo.attrib["units"] = "degrees_east"
    lo.attrib["standard_name"] = "longitude"
    lo[:] = lon

    la = defVar(ds, "lat", Float32, ("lat",))
    la.attrib["units"] = "degrees_north"
    la.attrib["standard_name"] = "latitude"
    la[:] = lat

    lai_var = defVar(ds, "lai", Float32, ("lon", "lat"))
    lai_var.attrib["units"] = "m^2 m^-2"
    lai_var.attrib["standard_name"] = "leaf_area_index"
    lai_var.attrib["long_name"] = "Maximum leaf area index of the land part of the grid cell"
    lai_var[:, :] = max_lai

    fland_var = defVar(ds, "land_fraction", Float32, ("lon", "lat"))
    fland_var.attrib["units"] = "1"
    fland_var.attrib["long_name"] = "ERA5 land fraction used for the correction"
    fland_var[:, :] = fland
end

create_artifact_guided(OUTPUT_DIR; artifact_name = basename(@__DIR__))
