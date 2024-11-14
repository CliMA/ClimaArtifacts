"""
   postprocess_and_make_weekly_lai_data(ncin, fileout)

Take `ncin`, a .nc file loaded using NCDatasets, and write a postprocessed version to
`fileout`.

The variables kept are "lai_lv" and "lai_hv".

Postprocessing includes:
- Updating history for global attributes.
- The attribute `_FILLVALUE` is removed from the attributes of the variables "longitude" and
  "latitude".
- For all variables beside time, longitude, and latitude, every attribute is removed except
  `standard_name`, `long_name`, `units`, `_FillValue`, and `missing_value`.
- Reverse latitude dimension so that the latitudes are in increasing order.
- All variables are stored as Float32 except for the time dimension which is stored as Int32
  (these are converted to dates when loading them in Julia).
- Weekly data is kept which ranges from 2008-01-01 to 2008-12-23; the date 2008-12-30
  excluded as it does not constitute a full week
"""
function postprocess_and_make_weekly_lai_data(ncin, fileout)
    global_attrib = OrderedDict(ncin.attrib)
    curr_history = global_attrib["history"]
    new_history =
        curr_history *
        "; Modified by CliMA for use in ClimaLand models (see era5_land_forcing_data2008 folder in ClimaArtifacts for full changes)"
    global_attrib["history"] = new_history
    ncout = NCDataset(fileout, "c", attrib = global_attrib)

    n_hours = length(ncin["valid_time"])
    ntime = Int(floor(n_hours / (7 * 24)))
    times = (0:1:(ntime-1)) .* 7 .* 24 .+ 1

    defDim(ncout, "time", ntime)
    defDim(ncout, "lon", Int(ceil(length(ncin["longitude"]))))
    defDim(ncout, "lat", Int(ceil(length(ncin["latitude"]))))

    time_ = defVar(
        ncout,
        "time",
        Int32,
        ("time",),
        attrib = ncin["valid_time"].attrib,
        deflatelevel = 9,
    )

    time_[:] = Array(ncin["valid_time"])[times]

    lon = defVar(
        ncout,
        "lon",
        Float32,
        ("lon",),
        attrib = delete!(copy(ncin["longitude"].attrib), "_FillValue"),
        deflatelevel = 9,
    )
    lon[:] = Array(ncin["longitude"])

    lat = defVar(
        ncout,
        "lat",
        Float32,
        ("lat",),
        attrib = copy(ncin["latitude"].attrib) |>
                 x -> delete!(x, "_FillValue") |> x -> delete!(x, "stored_direction"),
        deflatelevel = 9,
    )

    # Reverse latitude dimension so that the elements are in increasing order
    lat[:] = reverse(Array(ncin["latitude"]))


    varnames = ["lai_hv", "lai_lv"]

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
            deflatelevel = 9,
        )
        ncout[varname][:, :, :] = reverse(ncin[varname][:, :, times], dims = 2)
    end

    close(ncout)
end
