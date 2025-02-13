using NCDatasets

"""
    remove_time_dims_from_covers(in_path, out_path)

Remake a NetCDF file and save it at `out_path` by removing time dimension and
reversing the latitude dimension from the NetCDF file located at `in_path`.
"""
function remove_time_dim_from_covers(in_path, out_path)
    ds_in = NCDataset(in_path)

    # Make new dataset
    attribs = copy(ds_in.attrib)
    attribs["history"] *= "; Modified by CliMA for use in ClimaLand models (see era5_lai_covers folder in ClimaArtifacts for full changes)"
    ds_out = NCDataset(out_path, "c", attrib=attribs)

    # Define dimensions (omit time dimension)
    ds_out.dim["latitude"] = length(ds_in["latitude"][:])
    ds_out.dim["longitude"] = length(ds_in["longitude"][:])

    defVar(ds_out, "number", collect(ds_in["number"]), (), attrib=ds_in["number"].attrib)
    defVar(
        ds_out,
        "latitude",
        # reverse latitude dimension because latitude is in decreasing order
        reverse(collect(ds_in["latitude"])),
        ("latitude",),
        attrib=ds_in["latitude"].attrib,
    )
    defVar(
        ds_out,
        "longitude",
        collect(ds_in["longitude"]),
        ("longitude",),
        attrib=ds_in["longitude"].attrib,
    )

    # Check that values of high vegetation cover + low vegetation cover is
    # between 0 and 1
    # Reverse here because we are reversing the latitude dimension
    cvh = reverse(ds_in["cvh"][:, :, 1], dims=2)
    cvl = reverse(ds_in["cvl"][:, :, 1], dims=2)
    if !((0 <= minimum(cvh + cvl)) && (maximum(cvh + cvl) <= 1))
        return error("Values of CVH is not between 0 and 1")
    end
    if !((0 <= minimum(cvl)) && (maximum(cvl) <= 1))
        return error("Values of CVL is not between 0 and 1")
    end

    defVar(
        ds_out,
        "cvh",
        cvh,
        ("longitude", "latitude"),
        attrib=ds_in["cvh"].attrib,
    )
    defVar(
        ds_out,
        "cvl",
        cvl,
        ("longitude", "latitude"),
        attrib=ds_in["cvl"].attrib,
    )

    close(ds_in)
    close(ds_out)
end
