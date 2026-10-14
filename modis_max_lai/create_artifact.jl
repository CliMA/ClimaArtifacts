# MODIS maximum LAI (2000-2020) at 0.25°: for each cell, the maximum over all
# months of the yearly files of the `modis_lai_0.25deg` artifact (LAI of the
# land part of each cell).

using Artifacts
using NCDatasets

using ClimaArtifactsHelper

const YEARS = 2000:2020

# LAI is stored as Int16 with this scale factor, as in the yearly files
const LAI_SCALE_FACTOR = 0.001f0

const OUTPUTS = [
    (
        source_name = "modis_lai_0.25deg",
        source = artifact"modis_lai_0.25deg",
        suffix = "0.25x0.25",
        name = "modis_max_lai_0.25deg",
        file = "modis_max_lai_0.25x0.25.nc",
    ),
]

for out in OUTPUTS
    output_dir = out.name * "_artifact"
    if isdir(output_dir)
        @warn "$output_dir already exists. Content will end up in the artifact and may be overwritten."
        @warn "Abort this calculation, unless you know what you are doing."
    else
        mkdir(output_dir)
    end

    files = [joinpath(out.source, "Yuan_et_al_$(year)_$(out.suffix).nc") for year in YEARS]
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

    NCDataset(joinpath(output_dir, out.file), "c") do ds
        defDim(ds, "lon", length(lon))
        defDim(ds, "lat", length(lat))

        ds.attrib["title"] = "MODIS maximum LAI ($(first(YEARS))-$(last(YEARS))) of the land part of each cell"
        ds.attrib["source"] = "Maximum over all months of the yearly files of the $(out.source_name) artifact"
        ds.attrib["history"] = "Created by CliMA (see modis_max_lai folder in ClimaArtifacts)"

        lo = defVar(ds, "lon", Float32, ("lon",))
        lo.attrib["units"] = "degrees_east"
        lo.attrib["standard_name"] = "longitude"
        lo[:] = lon

        la = defVar(ds, "lat", Float32, ("lat",))
        la.attrib["units"] = "degrees_north"
        la.attrib["standard_name"] = "latitude"
        la[:] = lat

        lai_var = defVar(
            ds, "lai", Int16, ("lon", "lat");
            deflatelevel = 5, shuffle = true,
            attrib = ["scale_factor" => LAI_SCALE_FACTOR, "add_offset" => 0.0f0],
        )
        lai_var.attrib["units"] = "m^2 m^-2"
        lai_var.attrib["standard_name"] = "leaf_area_index"
        lai_var.attrib["long_name"] = "Maximum leaf area index of the land part of the grid cell"
        lai_var[:, :] = max_lai

        fland_var = defVar(ds, "land_fraction", Float32, ("lon", "lat"); deflatelevel = 5, shuffle = true)
        fland_var.attrib["units"] = "1"
        fland_var.attrib["long_name"] = "Land fraction of the cell (ETOPO 2022 30 arc-second land-sea mask, lakes removed, land below sea level added)"
        fland_var[:, :] = fland
    end
end

create_artifact_guided(OUTPUTS[1].name * "_artifact"; artifact_name = OUTPUTS[1].name)
