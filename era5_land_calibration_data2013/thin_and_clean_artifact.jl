"""
   thin_and_clean_artifact(
       filein,
       fileout,
       varname;
       THINNING_FACTOR = 8,
   )
Take the file in `filein` and write a cleaned thinned-down version to `fileout`
for the given `varname`. Thinning means taking one every `THINNING_FACTOR`
points.
"""
function thin_and_clean_artifact(ncin, fileout; THINNING_FACTOR = 8)
    ncout = NCDataset(fileout, "c")

    defDim(ncout, "time", length(Array(ncin["valid_time"])))
    defDim(ncout, "lon", Int(ceil(length(ncin["longitude"]) // THINNING_FACTOR)))
    defDim(ncout, "lat", Int(ceil(length(ncin["latitude"]) // THINNING_FACTOR)))

    time_ = defVar(
        ncout,
        "time",
        Int32,
        ("time",),
        attrib = ncin["valid_time"].attrib,
        deflatelevel = 9,
    )

    time_[:] = Array(ncin["valid_time"])

    lon = defVar(
        ncout,
        "lon",
        Float64,
        ("lon",),
        attrib = delete!(copy(ncin["longitude"].attrib), "_FillValue"),
        deflatelevel = 9,
    )
    lon[:] = Array(ncin["longitude"])[begin:THINNING_FACTOR:end]

    lat = defVar(
        ncout,
        "lat",
        Float64,
        ("lat",),
        attrib = delete!(copy(ncin["latitude"].attrib), "_FillValue"),
        deflatelevel = 9,
    )

    # Reverse latitude dimension so that the elements are in increasing order
    lat[:] = Array(ncin["latitude"])[begin:THINNING_FACTOR:end]

    varnames = setdiff(Set(keys(ncin)), NCDatasets.dimnames(ncin))
    varnames_to_remove = ["number", "expver"]
    varnames = setdiff(varnames, varnames_to_remove)

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
        ncout[varname][:, :, :] = reverse(
            vncin[varname][begin:THINNING_FACTOR:end, begin:THINNING_FACTOR:end, :],
            dims = 2,
        )
    end

    close(ncin)
    close(ncout)
end
