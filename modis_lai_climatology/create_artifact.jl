# MODIS LAI monthly climatology (2000-2020): for each month, the mean of the
# land-fraction corrected yearly files of the `modis_lai` artifact.

using Artifacts
using Dates
using NCDatasets

using ClimaArtifactsHelper

const OUTPUT_DIR = basename(@__DIR__) * "_artifact"
const OUTPUT_FILE = "modis_lai_climatology.nc"
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
lai = zeros(length(lon), length(lat), 12)
for file in files
    NCDataset(file) do ds
        @assert ds["lon"][:] == lon && ds["lat"][:] == lat
        @assert ds["land_fraction"][:, :] == fland
        lai .+= ds["lai"][:, :, :]
    end
end
lai ./= length(files)

NCDataset(joinpath(OUTPUT_DIR, OUTPUT_FILE), "c") do ds
    defDim(ds, "lon", length(lon))
    defDim(ds, "lat", length(lat))
    defDim(ds, "time", 12)

    ds.attrib["title"] = "MODIS LAI monthly climatology ($(first(YEARS))-$(last(YEARS))), land-fraction corrected"
    ds.attrib["source"] = "Mean of the yearly files of the modis_lai artifact"
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

    lai_var = defVar(ds, "lai", Float32, ("lon", "lat", "time"))
    lai_var.attrib["units"] = "m^2 m^-2"
    lai_var.attrib["standard_name"] = "leaf_area_index"
    lai_var.attrib["long_name"] = "Leaf area index of the land part of the grid cell"
    lai_var[:, :, :] = lai

    fland_var = defVar(ds, "land_fraction", Float32, ("lon", "lat"))
    fland_var.attrib["units"] = "1"
    fland_var.attrib["long_name"] = "ERA5 land fraction used for the correction"
    fland_var[:, :] = fland
end

create_artifact_guided(OUTPUT_DIR; artifact_name = basename(@__DIR__))
