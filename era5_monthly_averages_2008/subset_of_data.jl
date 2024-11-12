using NCDatasets
using Dates

"""
    create_new_ds_from_time_indx(
        input_ds::NCDataset,
        time_indx::Vector{Int},
        output_path::String,
    )
Creates and processes a dataset from a subset of the time dimension of the input dataset.

This extracts data from the input dataset for the given time indices, and creates a new dataset.
The new dataset also contains two new variables, `msuwlwrf` and `msuwswrf`, which are the
upward long-wave and short-wave radiation fluxes, respectively. These are calculated as the
difference between the downward and net radiation fluxes.
"""
function create_new_ds_from_time_indx(
    input_ds::NCDataset,
    time_indx::Vector{Int},
    output_path::String,
)
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
    defDim(output_ds, "time", length(time_indx))
    ignored_attribs = ["_FillValue", "missing_value", "add_offset", "scale_factor"]
    for (varname, var) in input_ds
        if !(
            varname in
            ["latitude", "longitude", "time", "msdwlwrf", "msdwswrf", "msnlwrf", "msnswrf"]
        )
            attrib = copy(var.attrib)
            for attrib_name in ignored_attribs
                delete!(attrib, attrib_name)
            end
            # the _FillValue attribute is automatically added by NCDatasets
            # store everything as Float32 to save space, and max compression (lossless)
            defVar(
                output_ds,
                varname,
                Float32.(reverse(var[:, :, time_indx], dims = 2)),
                dimnames(var);
                attrib = attrib,
                deflatelevel = 9,
            )
        end
    end
    # calculate upward radiation flux as the difference between downward and net radiation
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
        deflatelevel = 9,
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
        deflatelevel = 9,
    )
    # convert time to standard
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
