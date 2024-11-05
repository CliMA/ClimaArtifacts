using NCDatasets

"""
    find_corrupted_and_missing_nc_files(first_year, last_year, last_month)

Find corrupted and missing .nc files. Print the number of missing files and the missing
files. If a file is corrupted, then an error is immediately thrown.

A file is corrupted if:
    1. Variables are missing
    2. It cannot be open using NCDatasets
    3. Duplicated points in time dimension
    4. Time dimension is not sorted
"""
function find_corrupted_and_missing_nc_files(first_year, last_year, last_month)
    years = first_year:1:last_year
    months = ["01", "02", "03", "04", "05", "06", "07", "08", "09", "10", "11", "12"]
    file_names =
        ["era5_forcing_data_$(year)_$(month).nc" for year in years for month in months]
    file_names = file_names[begin:end-(12-last_month)]

    era_5_dirs = []
    for (_, dirs, _) in walkdir(".")
        for dir in dirs
            if startswith(dir, "era_5")
                push!(era_5_dirs, dir)
            end
        end
    end

    rate_files = []
    inst_files = []

    for dir in era_5_dirs
        files = readdir(dir, join = true)
        for file in filter(x -> endswith(x, ".nc"), files)
            println("Checking $file")
            ds = NCDataset(file)
            attribs = keys(ds)
            # Data should contain all the variables
            if !(occursin("rate", file) || occursin("inst", file))
                if !issubset(
                    [
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
                        "lai_hv",
                        "lai_lv",
                    ],
                    attribs,
                )
                    println("$file is corrupted; does not contain all the variables")
                    close(ds)
                    continue
                end
                # Data should contain only the instantaneous variables
            elseif occursin("inst", file)
                if !issubset(
                    ["u10", "v10", "d2m", "t2m", "sp", "lai_hv", "lai_lv"],
                    attribs,
                )
                    println("$file is corrupted; does not contain all the variables")
                    close(ds)
                    continue
                end
            else
                # Data should contain only rate variables
                if !issubset(["msr", "msdrswrf", "msdwlwrf", "msdwswrf", "mtpr"], attribs)
                    println("$file is corrupted; does not contain all the variables")
                    close(ds)
                    continue
                end
            end
            # Check for duplicate time points
            if !(unique(ds["valid_time"][:]) != length(ds["valid_time"][:]))
                println("$file is corrupted; duplicated points in time dimension")
                close(ds)
                continue
            end
            # Check if time dimension is sorted
            if !issorted(ds["valid_time"][:])
                println("$file is corrupted, time dimension is not sorted")
                close(ds)
                continue
            end
            close(ds)
            filter!(fname -> fname != basename(file), file_names)

            occursin("rate", file) && push!(rate_files, basename(file))
            occursin("inst", file) && push!(inst_files, basename(file))
        end
    end

    without_rate_files = [chop(filename, tail = 8) * ".nc" for filename in rate_files]
    without_inst_files = [chop(filename, tail = 8) * ".nc" for filename in inst_files]
    rate_and_inst_files = intersect(without_rate_files, without_inst_files)
    filter!(fname -> !(fname in rate_and_inst_files), file_names)
    println("Missing or corrupted files: $file_names")
    println("Missing or corrupted file count: $(length(file_names))")
    return nothing
end

if abspath(PROGRAM_FILE) == @__FILE__
    if length(ARGS) != 3
        error(
            "Script takes in three arguments: start year (inclusive), end year (inclusive), and last month",
        )
    end

    # Check whether ERA5 data exists from the first month of first_year to last_month of last_year
    first_year = parse(Int, ARGS[1])
    last_year = parse(Int, ARGS[2])
    last_month = parse(Int, ARGS[3])
    find_corrupted_and_missing_nc_files(first_year, last_year, last_month)
end
