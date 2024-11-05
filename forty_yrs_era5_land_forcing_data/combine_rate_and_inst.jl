"""
    combine_rate_and_inst(output_filepath, rate_filepath, inst_filepath)

Stitch the datasets `rate_filepath` and `inst_filepath` by concatenating the variables
together and save the new dataset as `output_filepath`.
"""
function combine_rate_and_inst(output_filepath, rate_filepath, inst_filepath)
    # Load datasets
    nc_rate = NCDataset(rate_filepath)
    nc_inst = NCDataset(inst_filepath)

    # Make new dataset
    ds = NCDataset(output_filepath, "c", attrib = nc_rate.attrib)

    defDim(ds, "valid_time", length(Array(nc_rate["valid_time"])))
    defDim(ds, "latitude", length(Array(nc_rate["latitude"][:])))
    defDim(ds, "longitude", length(Array(nc_rate["longitude"][:])))

    # Define variables
    ncnumber = defVar(ds, "number", Int64, (), attrib = nc_rate["number"].attrib)
    ncvalid_time = defVar(
        ds,
        "valid_time",
        Int64,
        ("valid_time",),
        attrib = nc_rate["valid_time"].attrib,
    )
    nclatitude =
        defVar(ds, "latitude", Float64, ("latitude",), attrib = nc_rate["latitude"].attrib)
    nclongitude = defVar(
        ds,
        "longitude",
        Float64,
        ("longitude",),
        attrib = nc_rate["longitude"].attrib,
    )
    ncexpver = defVar(ds, "expver", String, ("valid_time",))

    # Get values from dataset containing rate variables
    ncnumber[] = Array(nc_rate["number"])
    ncvalid_time[:] = Array(nc_rate["valid_time"])
    nclatitude[:] = Array(nc_rate["latitude"])
    nclongitude[:] = Array(nc_rate["longitude"])
    ncexpver[:] = Array(nc_rate["expver"])

    # Save all rate variables
    rate_var_names = ["msr", "msdrswrf", "msdwlwrf", "msdwswrf", "mtpr"]
    for var_name in rate_var_names
        defVar(
            ds,
            var_name,
            Float32,
            ("longitude", "latitude", "valid_time"),
            attrib = nc_rate[var_name].attrib,
        )
        ds[var_name][:, :, :] = nc_rate[var_name][:, :, :]
    end

    # Save all inst variables
    inst_var_names = ["u10", "v10", "d2m", "t2m", "sp", "lai_lv", "lai_hv"]
    for var_name in inst_var_names
        defVar(
            ds,
            var_name,
            Float32,
            ("longitude", "latitude", "valid_time"),
            attrib = nc_inst[var_name].attrib,
        )
        ds[var_name][:, :, :] = nc_inst[var_name][:, :, :]
    end

    close(nc_rate)
    close(nc_inst)
    close(ds)
end
