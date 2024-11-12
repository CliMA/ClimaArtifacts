using NCDatasets
using Dates

"""
    create_monthly_ds_surface(input_ds, output_path)

Processes the `input_ds` dataset to convert the time dimension to DateTimes,
and add the `msuwlwrf` and `msuwswrf` variables, which are the upward
long-wave and short-wave radiation fluxes, respectively. Only surface variables are kept.
"""
function create_monthly_ds_surface(input_ds, output_path)
    if isfile(output_path)
        rm(output_path)
        @info "Removed existing file $output_path"
    end

    output_ds = NCDataset(output_path, "c")
    for (attrib_name, attrib_value) in input_ds.attrib
        output_ds.attrib[attrib_name] = attrib_value
    end
    defDim(output_ds, "longitude", input_ds.dim["longitude"])
    defDim(output_ds, "latitude", input_ds.dim["latitude"])
    defDim(output_ds, "time", input_ds.dim["date"])
    ignored_attribs =
        ["_FillValue", "missing_value", "add_offset", "scale_factor", "coordinates"]
    for (varname, var) in input_ds
        if !(
            varname in [
                "latitude",
                "longitude",
                "date",
                "msdwlwrf",
                "msdwswrf",
                "msnlwrf",
                "msnswrf",
                "expver",
                "number",
                "tcw",
            ]
        )
            attrib = copy(var.attrib)
            for (key, value) in attrib
                if key in ignored_attribs ||
                   occursin("GRIB", key) ||
                   attrib[key] == "unknown"
                    delete!(attrib, key)
                end
            end
            # the _FillValue attribute is automatically added by NCDatasets
            # store everything as Float32 to save space, and max compression (lossless)
            defVar(
                output_ds,
                varname,
                Float32.(reverse(var[:, :, :], dims = 2)),
                (dimnames(var)[1:2]..., "time");
                attrib = attrib,
                deflatelevel = 9,
            )
        end
    end
    defVar(
        output_ds,
        "expver",
        input_ds["expver"][:],
        ("time",);
        attrib = input_ds["expver"].attrib,
    )
    defVar(
        output_ds,
        "msuwlwrf",
        Float32.(
            reverse(
                input_ds["msdwlwrf"][:, :, :] .- input_ds["msnlwrf"][:, :, :],
                dims = 2,
            )
        ),
        ("longitude", "latitude", "time"),
        attrib = (
            "units" => "W m**-2",
            "long_name" => "Mean surface upward long-wave radiation flux",
        ),
        deflatelevel = 9,
    )
    defVar(
        output_ds,
        "msuwswrf",
        Float32.(
            reverse(
                input_ds["msdwswrf"][:, :, :] .- input_ds["msnswrf"][:, :, :],
                dims = 2,
            )
        ),
        ("longitude", "latitude", "time"),
        attrib = (
            "units" => "W m**-2",
            "long_name" => "Mean surface upward short-wave radiation flux",
        ),
        deflatelevel = 9,
    )

    defVar(
        output_ds,
        "latitude",
        reverse(input_ds["latitude"][:]),
        ("latitude",);
        attrib = delete!(copy(input_ds["latitude"].attrib), "stored_direction"),
    )

    defVar(
        output_ds,
        "longitude",
        input_ds["longitude"][:],
        ("longitude",);
        attrib = input_ds["longitude"].attrib,
    )

    # If data is requested as netcdf, and not netcdf_legacy, the data includes a date dimension
    # instead of time, where each date is an integer in the format yyyymmdd. Here we convert it to
    # a DateTime object, and set the day to the 15th of the month.
    new_times = map(input_ds["date"][:]) do t
        d = DateTime(string(t), "yyyymmdd")
        d + (Day(15) - Day(d))
    end

    # check that there are no duplicates and that it is sorted
    @assert issorted(new_times)
    for i = 2:length(new_times)
        @assert new_times[i] != new_times[i-1]
    end
    new_times_attribs = ["standard_name" => "time", "long_name" => "Time"]

    defVar(output_ds, "time", new_times, ("time",); attrib = new_times_attribs)
    close(output_ds)
end

"""
    create_monthly_ds_atmos(input_ds, output_path)

Processes the `input_ds` dataset to convert the time dimension to DateTimes,
and add the `msuwlwrf` and `msuwswrf` variables, which are the upward
long-wave and short-wave radiation fluxes, respectively. Only vertical integral variables are kept.
"""
function create_monthly_ds_atmos(input_ds, output_path)
    if isfile(output_path)
        rm(output_path)
        @info "Removed existing file $output_path"
    end

    output_ds = NCDataset(output_path, "c")
    for (attrib_name, attrib_value) in input_ds.attrib
        output_ds.attrib[attrib_name] = attrib_value
    end
    defDim(output_ds, "longitude", input_ds.dim["longitude"])
    defDim(output_ds, "latitude", input_ds.dim["latitude"])
    defDim(output_ds, "time", input_ds.dim["date"])
    ignored_attribs =
        ["_FillValue", "missing_value", "add_offset", "scale_factor", "coordinates"]
    var = input_ds["tcw"]


    attrib = copy(var.attrib)
    for (key, value) in attrib
        if key in ignored_attribs || occursin("GRIB", key) || attrib[key] == "unknown"
            delete!(attrib, key)
        end
    end
    # the _FillValue attribute is automatically added by NCDatasets
    # store everything as Float32 to save space, and max compression (lossless)
    defVar(
        output_ds,
        "tcw",
        Float32.(reverse(var[:, :, :], dims = 2)),
        (dimnames(var)[1:2]..., "time");
        attrib = attrib,
        deflatelevel = 9,
    )


    defVar(
        output_ds,
        "expver",
        input_ds["expver"][:],
        ("time",);
        attrib = input_ds["expver"].attrib,
    )

    defVar(
        output_ds,
        "latitude",
        reverse(input_ds["latitude"][:]),
        ("latitude",);
        attrib = delete!(copy(input_ds["latitude"].attrib), "stored_direction"),
    )

    defVar(
        output_ds,
        "longitude",
        input_ds["longitude"][:],
        ("longitude",);
        attrib = input_ds["longitude"].attrib,
    )
    # If data is requested as netcdf, and not netcdf_legacy, the data includes a date dimension
    # instead of time, where each date is an integer in the format yyyymmdd. Here we convert it to
    # a DateTime object, and set the day to the 15th of the month.
    new_times = map(input_ds["date"][:]) do t
        d = DateTime(string(t), "yyyymmdd")
        d + (Day(15) - Day(d))
    end

    # check that there are no duplicates and that it is sorted
    @assert issorted(new_times)
    for i = 2:length(new_times)
        @assert new_times[i] != new_times[i-1]
    end
    new_times_attribs = ["standard_name" => "time", "long_name" => "Time"]

    defVar(output_ds, "time", new_times, ("time",); attrib = new_times_attribs)
    close(output_ds)
end

"""
    process_hourly_data_surface(input_ds, output_path)

Processes the `input_ds` dataset to add the `msuwlwrf` and `msuwswrf` variables, which are the upward
long-wave and short-wave radiation fluxes, respectively. Only surface variables are kept.
"""
function process_hourly_data_surface(input_ds, output_path)
    if isfile(output_path)
        rm(output_path)
        @info "Removed existing file $output_path"
    end

    output_ds = NCDataset(output_path, "c")
    defDim(output_ds, "longitude", input_ds.dim["longitude"])
    defDim(output_ds, "latitude", input_ds.dim["latitude"])

    # When requesting data in a netcdf, CDS converts a GRIB to netcdf. During this process,
    # extra data points are added. In this case, each month has 7 extra data points, where all the data
    # is missing. We remove these data points, and checked the removed data is actually missing.
    ignore_mod_31 = [2, 4, 6, 8, 10, 12, 14]
    time_indx = filter(i -> !(i % 31 in ignore_mod_31), 1:length(input_ds["time"][:]))
    defDim(output_ds, "time", length(time_indx))
    missing_indices = filter(i -> (i % 31 in ignore_mod_31), 1:length(input_ds["time"][:]))
    for index in missing_indices
        if !all(input_ds["msdwswrf"][:, :, index] .=== missing)
            @error "The index pattern of the invalid data is not as expected"
        end
    end
    ignored_attribs = ["_FillValue", "missing_value", "add_offset", "scale_factor"]
    deflatelevel = 9
    for (varname, var) in input_ds
        if !(
            varname in [
                "latitude",
                "longitude",
                "time",
                "msdwlwrf",
                "msdwswrf",
                "msnlwrf",
                "msnswrf",
                "tcw",
            ]
        )
            attrib = copy(var.attrib)
            for attrib_name in ignored_attribs
                delete!(attrib, attrib_name)
            end
            defVar(
                output_ds,
                varname,
                Float32.(reverse(var[:, :, time_indx], dims = 2)),
                dimnames(var);
                attrib = attrib,
                deflatelevel = deflatelevel,
            )
        end
    end
    defVar(
        output_ds,
        "msuwlwrf",
        Float32.(
            reverse(
                input_ds["msdwlwrf"][:, :, time_indx] .-
                input_ds["msnlwrf"][:, :, time_indx],
                dims = 2,
            )
        ),
        ("longitude", "latitude", "time"),
        attrib = (
            "units" => "W m**-2",
            "long_name" => "Mean surface upward long-wave radiation flux",
        ),
        deflatelevel = deflatelevel,
    )
    defVar(
        output_ds,
        "msuwswrf",
        Float32.(
            reverse(
                input_ds["msdwswrf"][:, :, time_indx] .-
                input_ds["msnswrf"][:, :, time_indx],
                dims = 2,
            )
        ),
        ("longitude", "latitude", "time"),
        attrib = (
            "units" => "W m**-2",
            "long_name" => "Mean surface upward short-wave radiation flux",
        ),
        deflatelevel = deflatelevel,
    )
    # center times on 15th of each month
    new_times = map(input_ds["time"][time_indx]) do t
        t + (Day(15) - Day(t))
    end
    # check that there are no duplicates and that it is sorted
    @assert issorted(new_times)
    for i = 2:length(new_times)
        @assert new_times[i] != new_times[i-1]
    end
    new_times_attribs = ["standard_name" => "time", "long_name" => "Time"]

    defVar(output_ds, "time", new_times, ("time",); attrib = new_times_attribs)

    defVar(
        output_ds,
        "latitude",
        reverse(input_ds["latitude"][:]),
        ("latitude",);
        attrib = input_ds["latitude"].attrib,
    )

    defVar(
        output_ds,
        "longitude",
        input_ds["longitude"][:],
        ("longitude",);
        attrib = input_ds["longitude"].attrib,
    )
    close(output_ds)
end

"""
    process_hourly_data_atmos(input_ds, output_path)

Processes the `input_ds` dataset to add the `msuwlwrf` and `msuwswrf` variables, which are the upward
long-wave and short-wave radiation fluxes, respectively. Only vertical integral variables are kept.
"""
function process_hourly_data_atmos(input_ds, output_path)
    if isfile(output_path)
        rm(output_path)
        @info "Removed existing file $output_path"
    end

    output_ds = NCDataset(output_path, "c")
    defDim(output_ds, "longitude", input_ds.dim["longitude"])
    defDim(output_ds, "latitude", input_ds.dim["latitude"])

    # When requesting data in a netcdf, CDS converts a GRIB to netcdf. During this process,
    # extra data points are added. In this case, each month has 7 extra data points, where all the data
    # is missing. We remove these data points, and checked the removed data is actually missing.
    ignore_mod_31 = [1, 3, 5, 7, 9, 11, 13]
    time_indx = filter(i -> !(i % 31 in ignore_mod_31), 1:length(input_ds["time"][:]))
    defDim(output_ds, "time", length(time_indx))
    missing_indices = filter(i -> (i % 31 in ignore_mod_31), 1:length(input_ds["time"][:]))
    for index in missing_indices
        if !all(input_ds["tcw"][:, :, index] .=== missing)
            @error "The index pattern of the invalid data is not as expected"
        end
    end
    ignored_attribs = ["_FillValue", "missing_value", "add_offset", "scale_factor"]
    deflatelevel = 9
    var = input_ds["tcw"]
    attrib = copy(var.attrib)
    for attrib_name in ignored_attribs
        delete!(attrib, attrib_name)
    end
    defVar(
        output_ds,
        "tcw",
        Float32.(reverse(var[:, :, time_indx], dims = 2)),
        dimnames(var);
        attrib = attrib,
        deflatelevel = deflatelevel,
    )


    # center times on 15th of each month
    new_times = map(input_ds["time"][time_indx]) do t
        t + (Day(15) - Day(t))
    end
    # check that there are no duplicates and that it is sorted
    @assert issorted(new_times)
    for i = 2:length(new_times)
        @assert new_times[i] != new_times[i-1]
    end
    new_times_attribs = ["standard_name" => "time", "long_name" => "Time"]

    defVar(output_ds, "time", new_times, ("time",); attrib = new_times_attribs)

    defVar(
        output_ds,
        "latitude",
        reverse(input_ds["latitude"][:]),
        ("latitude",);
        attrib = input_ds["latitude"].attrib,
    )

    defVar(
        output_ds,
        "longitude",
        input_ds["longitude"][:],
        ("longitude",);
        attrib = input_ds["longitude"].attrib,
    )
    close(output_ds)
end

"""
    fix_current_year(input_ds, output_path)

Processes the `input_ds` dataset to remove the `expver` dimension
"""
function fix_current_year(input_ds, output_path)
    if isfile(output_path)
        rm(output_path)
        @info "Removed existing file $output_path"
    end
    ignored_attribs =
        ["_FillValue", "missing_value", "add_offset", "scale_factor", "coordinates"]
    output_ds = NCDataset(output_path, "c")
    defDim(output_ds, "longitude", input_ds.dim["longitude"])
    defDim(output_ds, "latitude", input_ds.dim["latitude"])
    defDim(output_ds, "time", input_ds.dim["time"])
    for (varname, var) in input_ds
        if !(varname in ["latitude", "longitude", "time", "expver"])
            attrib = copy(var.attrib)
            for (key, value) in attrib
                if key in ignored_attribs
                    delete!(attrib, key)
                end
            end
            defVar(
                output_ds,
                varname,
                remove_expver_dim(input_ds, output_ds, varname),
                ("longitude", "latitude", "time");
                attrib = attrib,
            )
        end
    end
    defVar(
        output_ds,
        "time",
        input_ds["time"][:],
        ("time",);
        attrib = input_ds["time"].attrib,
    )
    defVar(
        output_ds,
        "longitude",
        input_ds["longitude"][:],
        ("longitude",);
        attrib = input_ds["longitude"].attrib,
    )
    defVar(
        output_ds,
        "latitude",
        input_ds["latitude"][:],
        ("latitude",);
        attrib = input_ds["latitude"].attrib,
    )
    close(output_ds)
end

"""
    remove_expver_dim(input_ds, output_ds, varname)

Removes the `expver` dimension from the variable `varname` in the `input_ds`
"""
function remove_expver_dim(input_ds, output_ds, varname)
    input_dims = size(input_ds[varname])
    out_var = similar(input_ds[varname][:], input_dims[1], input_dims[2], input_dims[4])
    for i = 1:input_dims[4]
        if input_ds[varname][1, 1, 1, i] !== missing
            out_var[:, :, i] .= input_ds[varname][:, :, 1, i]
        elseif input_ds[varname][1, 1, 2, i] !== missing
            out_var[:, :, i] .= input_ds[varname][:, :, 2, i]
        elseif all(input_ds[varname][:, :, 1, i] .!== missing)
            out_var[:, :, i] .= input_ds[varname][:, :, 1, i]
        else
            out_var[:, :, i] .= input_ds[varname][:, :, 2, i]
        end
    end
    return out_var
end
