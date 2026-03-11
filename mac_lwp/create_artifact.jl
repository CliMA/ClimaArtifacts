import Dates
import Downloads
using NCDatasets
using ClimaArtifactsHelper

const base_url = "https://measures.gesdisc.eosdis.nasa.gov/data/LWP/MACLWP_mean.1"

mac_lwp_links = ["$(base_url)/maclwp_cloudlwpave_$(year)_v1.nc4" for year in 1988:2016]

mac_lwp_dir_name = "mac_lwp_files"
mac_lwp_dir = abspath(mac_lwp_dir_name)
mkpath(mac_lwp_dir)

for url in mac_lwp_links
    fname = joinpath(mac_lwp_dir, basename(url))
    if !isfile(fname)
        @info "Downloading $(basename(fname))"
        Downloads.download(url, fname)
    else
        @info "Skipping $(basename(fname)) (already exists)"
    end
end

"""
    stitch_mac_lwp(files, output_filepath)

Concatenate all MAC-LWP files along the time dimension and write to `output_filepath`.

The `time` variable is replaced with a sequential index (months since 1988-01-01)
because each source file uses per-year time units.
"""
function stitch_mac_lwp(files, output_filepath)
    @info "Creating $output_filepath"

    mfds = NCDataset(files, aggdim = "time")

    global_attribs = Dict(mfds.attrib)
    global_attribs["history"] = "Modified by CliMA (see mac_lwp folder in ClimaArtifacts for full changes)"

    ds = NCDataset(output_filepath, "c", attrib = global_attribs)

    for dimname in dimnames(mfds)
        ds.dim[dimname] = mfds.dim[dimname]
    end

    for (varname, _) in mfds
        @info "Processing $varname"
        if varname == "time"
            # Downloaded files use a month index (0 - 11 for each month) to
            # represent the month
            # This is updated to use the monthly dates instead
            n = mfds.dim["time"]
            data = [Dates.DateTime(1988, 1, 1) + Dates.Month(i) for i in 0:(n - 1)]
            attrib = Dict(
                "long_name" => "time",
                "units" => "seconds since 1988-01-01 00:00:00",
                "axis" => "T",
            )
            defVar(ds, varname, data, dimnames(mfds[varname]), attrib = attrib)
        else
            data = Array(mfds[varname])
            data = nomissing(data, NaN32)
            defVar(ds, varname, data, dimnames(mfds[varname]), attrib = mfds[varname].attrib)
        end
    end

    close(ds)
    close(mfds)
end

# Sort downloaded files by year (they are named maclwp_cloudlwpave_YEAR_v1.nc4)
mac_lwp_files = sort(
    filter(f -> endswith(f, ".nc4"), readdir(mac_lwp_dir, join = true)),
    by = f -> parse(Int, match(r"(\d{4})_v1", basename(f)).captures[1]),
)

output_filepath = joinpath(mac_lwp_dir, "mac_lwp.nc")
if isfile(output_filepath)
    @info "File at $output_filepath already exists; skipping the concatenation of MAC-LWP files "
else
    stitch_mac_lwp(mac_lwp_files, output_filepath)
end

"""
    make_artifact(filepath)

Make an artifact with the file at `filepath`.
"""
function make_artifact(filepath)
    output_dir = basename(@__DIR__) * "_artifact"
    if isdir(output_dir)
        @warn "$output_dir already exists. Content will end up in the artifact and may be overwritten."
        @warn "Abort this calculation, unless you know what you are doing."
    else
        mkdir(output_dir)
    end

    filename = last(splitpath(filepath))
    cp(filepath, joinpath(output_dir, filename), force = true)

    create_artifact_guided(output_dir; artifact_name = basename(@__DIR__))
end

make_artifact(output_filepath)
@info "You can now delete the directory $mac_lwp_dir_name"
