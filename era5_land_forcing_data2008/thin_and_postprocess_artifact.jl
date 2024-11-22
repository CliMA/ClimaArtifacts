"""
   thin_and_postprocess_artifact(
       ncin,
       fileout,
       THINNING_FACTOR = 8,
   )
Take a `ncin` ,a .nc file loaded using NCDatasets, and write a postprocessed thinned-down
version to `fileout`. Thinning means taking one every `THINNING_FACTOR` points.

The variables kept are "u10", "v10", "d2m", "t2m", "sp", "msr", "msdrswrf", "msdwlwrf",
"msdwswrf", and "mtpr".

Postprocessing includes:
- Updating history for global attributes.
- The attribute `_FILLVALUE` is removed from the attributes of the variables "longitude" and
  "latitude".
- For all variables beside time, longitude, and latitude, every attribute is removed except
  `standard_name`, `long_name`, `units`, `_FillValue`, and `missing_value`.
- Reverse latitude dimension so that the latitudes are in increasing order.
- All variables are stored as Float32 except for the time dimension which is stored as Int32
  (these are converted to dates when loading them in Julia).
"""
function thin_and_postprocess_artifact(ncin, fileout; THINNING_FACTOR = 8)
    global_attrib = OrderedDict(ncin.attrib)
    curr_history = global_attrib["history"]
    new_history =
        curr_history *
        "; Modified by CliMA for use in ClimaLand models (see era5_land_forcing_data2008 folder in ClimaArtifacts for full changes)"
    global_attrib["history"] = new_history
    ncout = NCDataset(fileout, "c", attrib = global_attrib)

    defDim(ncout, "time", length(Array(ncin["valid_time"])))
    defDim(ncout, "lon", Int(ceil(length(ncin["longitude"]) // THINNING_FACTOR)))
    defDim(ncout, "lat", Int(ceil(length(ncin["latitude"]) // THINNING_FACTOR)))

    time_ = defVar(
        ncout,
        "time",
        Int32,
        ("time",),
        attrib = ncin["valid_time"].attrib,
        deflatelevel = 0,
    )

    time_[:] = Array(ncin["valid_time"])

    lon = defVar(
        ncout,
        "lon",
        Float32,
        ("lon",),
        attrib = delete!(copy(ncin["longitude"].attrib), "_FillValue"),
        deflatelevel = 0,
    )
    lon[:] = Array(ncin["longitude"])[begin:THINNING_FACTOR:end]

    lat = defVar(
        ncout,
        "lat",
        Float32,
        ("lat",),
        attrib = copy(ncin["latitude"].attrib) |>
                 x -> delete!(x, "_FillValue") |> x -> delete!(x, "stored_direction"),
        deflatelevel = 0,
    )

    # Reverse latitude dimension so that the elements are in increasing order
    lat[:] = reverse(Array(ncin["latitude"]))[begin:THINNING_FACTOR:end]

    varnames = [
        "u10",
        "v10",
        "d2m",
        "t2m",
        "sp",
        "msr",
        "msdrswrf",
        "msdwlwrf",
        "msdwswrf",
        "mtpr",
    ]

    attrib_names =
        ["standard_name", "long_name", "units", "_FillValue", "GRIB_missingValue"]
    attrib_renames = ["standard_name", "long_name", "units", "_FillValue", "missing_value"]

    for varname in varnames
        @show varname
        attribs = Dict([
            attrib_rename => ncin[varname].attrib[attrib_name] for
            (attrib_name, attrib_rename) in zip(attrib_names, attrib_renames)
        ])
        defVar(
            ncout,
            varname,
            Float32,
            ("lon", "lat", "time"),
            attrib = attribs,
            deflatelevel = 0,
        )
        ncout[varname][:, :, :] = reverse(
            ncin[varname][begin:THINNING_FACTOR:end, begin:THINNING_FACTOR:end, :],
            dims = 2,
        )
    end

    close(ncout)
end
