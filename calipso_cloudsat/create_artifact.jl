using NCDatasets
using DataStructures
using ClimaArtifactsHelper

"""
    parse_year_season(path)

Given a file `path`, return a year and season as integers.

The seasons MAM, JJA, SON, and DJF map to 1, 2, 3, and 4.
"""
function parse_year_season(path)
    # File name should look like "2008-MAM-..."
    filename = last(splitpath(path))
    s = first(filename, 8)
    year, season = split(s, "-")
    SEASON_ORDER = Dict("MAM" => 1, "JJA" => 2, "SON" => 3, "DJF" => 4)
    return (parse(Int, year), SEASON_ORDER[season])
end

"""
    get_and_sort_files(dir)

Get all the NetCDF files and sort them by the year and season of each dataset.
"""
function get_and_sort_files(dir)
    files = readdir(dir, join = true)
    filter!(file -> endswith(file, ".nc"), files)

    # Sort by years and then seasons
    # For each year, the order of the seasons are "MAM", "JJA", "SON", "DJF"
    # Note that the first month is used, so 2006-DJF refers to Dec 2006, Jan
    # 2007, and Feb 2007
    sort!(files, by = parse_year_season)
    return files
end

"""
    stitch_cloud_data(files, output_filepath)

Stitch all the files along the time dimension and create a NetCDF file from it.

If the variable or dimension does not vary in time, then the variable or
dimension will be the same.
"""
function stitch_cloud_data(files, output_filepath)
    @info "Creating $output_filepath"
    # Make a MFDS
    mfds = NCDataset(
        files,
        aggdim = "time",
        deferopen = false,
        isnewdim = true,
        constvars = [
            "height_bounds",
            "lat",
            "lon",
            "height",
            "doop",
            "type",
            "localhour",
            "localhour_bounds",
        ],
    )

    # Create dataset with global attributes stitched from all the files
    global_attribs = create_global_attribs(files)
    global_attribs["history"] = "Modified by CliMA (see calipso_cloudsat folder in ClimaArtifacts for full changes)"
    ds = NCDataset(output_filepath, "c", attrib = global_attribs)

    # Define length of each dimension
    for dimname in dimnames(mfds)
        ds.dim[dimname] = mfds.dim[dimname]
    end

    # Define variables
    for (varname, _) in mfds
        @info "Processing $varname"
        check_var_attribs(files, varname)
        data = varname == "time" ? get_time_vec(files) : Array(mfds[varname])
        defVar(ds, varname, data, dimnames(mfds[varname]), attrib = mfds[varname].attrib)
    end

    # Close datasets
    close(ds)
    close(mfds)
end

"""
    create_global_attribs(files)

Return the global attributes of all the `files`.

If the attribute is the same across all the files, then the global attributes
contain the same attribute. If the attribute is not the same across all the
files, then the global attributes contain a vector of all the values of the
attributes.

Note that only the keys of the global attributes of the first file in `files` is
used.
"""
function create_global_attribs(files)
    attrib_vec = []
    for file in files
        NCDataset(file) do ds
            push!(attrib_vec, OrderedDict(ds.attrib))
        end
    end

    # Check if the keys are all the same in the global attributes
    same_keys = all(keys(attrib_vec[1]) == keys(attrib_vec[i]) for i = 2:length(attrib_vec))
    same_keys || error("The keys found in the global attributes are not all the same")

    # Get all the attributes that are the same across all the files
    same_attribs = [
        key for key in keys(attrib_vec[1]) if
        all(attrib_vec[i][key] == attrib_vec[1][key] for i = 2:length(attrib_vec))
    ]

    pairs = []
    for (key, val) in attrib_vec[1]
        if key in same_attribs
            push!(pairs, key => val)
        else
            new_val = typeof(val)[attrib[key] for attrib in attrib_vec]
            push!(pairs, key => new_val)
        end
    end
    return OrderedDict(pairs)
end

"""
    check_var_attribs(files, varname)

Check the attributes of the variable with the name `varname` is the same across
all the `files`.
"""
function check_var_attribs(files, varname)
    attrib_vec = []
    for file in files
        NCDataset(file) do ds
            push!(attrib_vec, OrderedDict(ds[varname].attrib))
        end
    end

    same_keys = all(keys(attrib_vec[1]) == keys(attrib_vec[i]) for i = 2:length(attrib_vec))
    same_keys || error("The keys found in the variable $varname are not all the same")
    return nothing
end

"""
    get_time_vec(files)

Return a vector of dates found by `files`.
"""
function get_time_vec(files)
    date_vec = []
    for file in files
        NCDataset(file) do ds
            push!(date_vec, Array(ds["time"])[])
        end
    end
    # Type of vector cannot be Any
    return [date_vec...]
end

"""
    make_artifact(filepath_names)

Make an artifact with the files in `filepath_names`.
"""
function make_artifact(filepath_names)
    output_dir = basename(@__DIR__) * "_artifact"
    if isdir(output_dir)
        @warn "$output_dir already exists. Content will end up in the artifact and may be overwritten."
        @warn "Abort this calculation, unless you know what you are doing."
    else
        mkdir(output_dir)
    end

    for filepath_name in filepath_names
        if endswith(filepath_name, "radarlidar_seasonal_2.5x2.5.nc")
            filename = last(splitpath(filepath_name))
            mv(filepath_name, joinpath(output_dir, filename), force = true)
        end
    end
    create_artifact_guided(output_dir; artifact_name = basename(@__DIR__))

    # Lowres
    output_dir_lowres = basename(@__DIR__) * "_lowres"
    if isdir(output_dir_lowres)
        @warn "$output_dir_lowres already exists. Content will end up in the artifact and may be overwritten."
        @warn "Abort this calculation, unless you know what you are doing."
    else
        mkdir(output_dir_lowres)
    end

    for filepath_name in filepath_names
        if endswith(filepath_name, "radarlidar_seasonal_10x10.nc")
            filename = last(splitpath(filepath_name))
            mv(filepath_name, joinpath(output_dir_lowres, filename), force = true)
        end
    end
    create_artifact_guided(
        output_dir_lowres;
        artifact_name = basename(@__DIR__) * "_lowres",
        append = true,
    )
end

radarlidar_dir_2_5 =
    joinpath(dirname(@__FILE__), "radarlidar_seasonal_data", "radarlidar_seasonal_2.5x2.5")
radarlidar_dir_10 =
    joinpath(dirname(@__FILE__), "radarlidar_seasonal_data", "radarlidar_seasonal_10x10")

# Check if the directory exists
for directory in (radarlidar_dir_10, radarlidar_dir_2_5)
    if !isdir(directory)
        error("$directory is not a directory. Check the file path passed in")
    end
end

# Loop over the directories containing the NetCDF files and create a netcdf file
# from them
filepath_names = []
for directory in (radarlidar_dir_10, radarlidar_dir_2_5)
    files = get_and_sort_files(directory)
    filename = last(splitpath(directory)) * ".nc"
    filepath_name = joinpath(dirname(directory), filename)
    stitch_cloud_data(files, filepath_name)
    push!(filepath_names, filepath_name)
end

make_artifact(filepath_names)
