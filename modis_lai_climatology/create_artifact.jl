# MODIS LAI monthly climatology (2000-2020) at 0.25°: for each month, the mean
# of the yearly files of the `modis_lai_0.25deg` artifact (LAI of the land part
# of each cell).

using Artifacts
using Dates
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
        name = "modis_lai_climatology_0.25deg",
        file = "modis_lai_climatology_0.25x0.25.nc",
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
    lai = zeros(length(lon), length(lat), 12)
    for file in files
        NCDataset(file) do ds
            @assert ds["lon"][:] == lon && ds["lat"][:] == lat
            @assert ds["land_fraction"][:, :] == fland
            lai .+= ds["lai"][:, :, :]
        end
    end
    lai ./= length(files)

    NCDataset(joinpath(output_dir, out.file), "c") do ds
        defDim(ds, "lon", length(lon))
        defDim(ds, "lat", length(lat))
        defDim(ds, "time", 12)

        ds.attrib["title"] = "MODIS LAI monthly climatology ($(first(YEARS))-$(last(YEARS))) of the land part of each cell"
        ds.attrib["source"] = "Mean of the yearly files of the $(out.source_name) artifact"
        ds.attrib["history"] = "Created by CliMA (see modis_lai_climatology folder in ClimaArtifacts)"

        lo = defVar(ds, "lon", Float32, ("lon",))
        lo.attrib["units"] = "degrees_east"
        lo.attrib["standard_name"] = "longitude"
        lo[:] = lon

        la = defVar(ds, "lat", Float32, ("lat",))
        la.attrib["units"] = "degrees_north"
        la.attrib["standard_name"] = "latitude"
        la[:] = lat

        # Uniform 30-day spacing, required by ClimaLand's PeriodicCalendar
        time = defVar(ds, "time", Int32, ("time",))
        time.attrib["units"] = "seconds since 1970-01-01"
        time.attrib["standard_name"] = "time"
        time.attrib["calendar"] = "proleptic_gregorian"
        time[:] = [Int32(datetime2unix(DateTime(2000) + Day(30(k - 1)))) for k in 1:12]

        lai_var = defVar(
            ds, "lai", Int16, ("lon", "lat", "time");
            deflatelevel = 5, shuffle = true, chunksizes = (length(lon), length(lat), 1),
            attrib = ["scale_factor" => LAI_SCALE_FACTOR, "add_offset" => 0.0f0],
        )
        lai_var.attrib["units"] = "m^2 m^-2"
        lai_var.attrib["standard_name"] = "leaf_area_index"
        lai_var.attrib["long_name"] = "Leaf area index of the land part of the grid cell"
        lai_var[:, :, :] = lai

        fland_var = defVar(ds, "land_fraction", Float32, ("lon", "lat"); deflatelevel = 5, shuffle = true)
        fland_var.attrib["units"] = "1"
        fland_var.attrib["long_name"] = "Land fraction of the cell (ETOPO 2022 30 arc-second land-sea mask, lakes removed, land below sea level added)"
        fland_var[:, :] = fland
    end
end

create_artifact_guided(OUTPUTS[1].name * "_artifact"; artifact_name = OUTPUTS[1].name)
