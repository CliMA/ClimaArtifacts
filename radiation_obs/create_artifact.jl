import ClimaArtifactsHelper
import Dates
import Downloads
using NCDatasets

"""
    download_from_txt_file(filepath_to_txt_file, output_dir)

Given a text file with download URL on each line, download the file serially
from each URL in `filepath_to_txt_file` and save them to `output_dir`.
"""
function download_from_txt_file(filepath_to_txt_file, output_dir)
    isfile(filepath_to_txt_file) || error("$filepath_to_txt_file is not a file")
    if isdir(output_dir)
        @warn "$output_dir already exists. Content will end up in directory and may be overwritten."
    else
        mkdir(output_dir)
    end

    file_urls = readlines(filepath_to_txt_file)
    # Filter out empty lines (the URL list may contain a leading or trailing blank line)
    filter!(!isempty, file_urls)
    for file_url in file_urls
        downloaded_file = Downloads.download(
            file_url,
            progress = ClimaArtifactsHelper.download_rate_callback(),
        )
        Base.mv(
            downloaded_file,
            joinpath(output_dir, basename(downloaded_file)),
            force = true,
        )
    end

end

"""
    get_dataset_to_nc_filepaths(output_dir)

Return a dictionary mapping dataset name to a sorted vector of NetCDF filepaths.

Dataset names are derived from filenames by stripping the trailing
`_YYYYMM-YYYYMM.nc` date-range suffix. Files within each dataset are sorted
by the first timestamp in their `time` dimension.
"""
function get_dataset_to_nc_filepaths(output_dir)
    all_nc_filepaths = readdir(output_dir)
    all_nc_filepaths = [joinpath(output_dir, fp) for fp in all_nc_filepaths]
    filter!(fp -> endswith(fp, ".nc"), all_nc_filepaths)

    # Group filepaths by dataset name (strip the date-range suffix)
    dataset_to_filepaths = Dict{String,Vector{String}}()

    for filepath in all_nc_filepaths
        filename = basename(filepath)
        dataset_name = replace(filename, r"_\d{6}-\d{6}\.nc$" => "")
        paths = get!(dataset_to_filepaths, dataset_name, [])
        push!(paths, filepath)
    end

    # Build a lookup from filepath to its first timestamp for sorting
    first_time_by_file = Dict{String,Any}()
    for filepath in all_nc_filepaths
        NCDataset(filepath) do ds
            first_time_by_file[filepath] = first(ds["time"])
        end
    end

    for paths in values(dataset_to_filepaths)
        sort!(paths, by = filepath -> first_time_by_file[filepath])
    end
    return dataset_to_filepaths
end

"""
    find_output_filename(dataset_entry)

Construct an output filename from `dataset_entry`, a `Pair` of a dataset name
and its sorted vector of source filepaths.

The filename has the form `<dataset_name>_<start_yyyymm>-<end_yyyymm>.nc`,
where the date range spans from the first timestamp of the first file to the
last timestamp of the last file.
"""
function find_output_filename(dataset_entry)
    dataset_name = first(dataset_entry)
    filepaths = last(dataset_entry)
    start_time = NCDataset(first(filepaths)) do ds
        return first(ds["time"])
    end
    end_time = NCDataset(last(filepaths)) do ds
        return last(ds["time"])
    end
    return "$(dataset_name)_" *
           Dates.format(start_time, "yyyymm") *
           "-" *
           Dates.format(end_time, "yyyymm") *
           ".nc"
end

"""
    concat_along_time_dim(dataset_to_filepaths)

Concatenate all variables in each dataset along the `time` dimension, write
the result to a new NetCDF file, and return a vector of paths to the
concatenated output files.

`dataset_to_filepaths` is a dictionary mapping dataset names to sorted vectors
of source filepaths (as returned by `get_dataset_to_nc_filepaths`). Missing
values in the source data are replaced with `NaN32`.
"""
function concat_along_time_dim(dataset_to_filepaths)
    concatenated_filepaths = String[]
    for dataset_entry in dataset_to_filepaths
        output_filepath = find_output_filename(dataset_entry)
        source_filepaths = last(dataset_entry)

        @info "Creating $output_filepath"
        multi_file_ds = NCDataset(source_filepaths, aggdim = "time")

        global_attribs = Dict(multi_file_ds.attrib)
        global_attribs["history"] = "Modified by CliMA (see radiation_obs folder in ClimaArtifacts for full changes)"

        out_ds = NCDataset(output_filepath, "c", attrib = global_attribs)

        for dimname in dimnames(multi_file_ds)
            out_ds.dim[dimname] = multi_file_ds.dim[dimname]
        end

        for (varname, _) in multi_file_ds
            @info "Processing $varname"
            data = Array(multi_file_ds[varname])
            data = nomissing(data, NaN32)
            defVar(
                out_ds,
                varname,
                data,
                dimnames(multi_file_ds[varname]),
                attrib = multi_file_ds[varname].attrib,
            )
        end

        close(out_ds)
        close(multi_file_ds)
        push!(concatenated_filepaths, output_filepath)
    end
    return concatenated_filepaths
end

# Download files
unprocessed_dir = "unprocessed_radiation_obs"
# download_from_txt_file("radiation_obs.txt", unprocessed_dir)
dataset_to_filepaths = get_dataset_to_nc_filepaths(unprocessed_dir)
concatenated_filepaths = concat_along_time_dim(dataset_to_filepaths)

# Create artifact
output_dir = basename(@__DIR__) * "_artifact"
if isdir(output_dir)
    @warn "$output_dir already exists. Content will end up in the artifact and may be overwritten."
    @warn "Abort this calculation, unless you know what you are doing."
else
    mkdir(output_dir)
end

for path in concatenated_filepaths
    cp(path, joinpath(output_dir, basename(path)), force = true)
end

ClimaArtifactsHelper.create_artifact_guided(output_dir; artifact_name = basename(@__DIR__))
