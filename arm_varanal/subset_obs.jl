using NCDatasets
using Dates

"""
    time_var_to_dates(ds, vname="time")

Read the time variable as `Date`s.

These ARM files have non-CF-compliant time `units` (e.g.
`"seconds since 2010-01-01 00.00, GMT"` and `"seconds since 2010-1-1 00:00:00.00, GMT"`),
which `NCDatasets`/`CommonDataModel` cannot decode to dates (it emits a warning
and returns raw numbers). We therefore read the raw `Variable` (no CF decoding)
and parse the reference date ourselves from the `seconds since YYYY-MM-DD` prefix.
"""
function time_var_to_dates(ds, vname = "time")
    v = NCDatasets.variable(ds, vname)   # raw Variable, no CF decoding
    units = v.attrib["units"]
    m = match(r"seconds since (\d+)-(\d+)-(\d+)", units)
    m === nothing && error("Cannot parse time units: $units")
    ref = DateTime(parse(Int, m[1]), parse(Int, m[2]), parse(Int, m[3]))
    return [Date(ref + Second(round(Int, t))) for t in v[:]]
end

"""
    subset_nc_by_time(src, dst, start_date, end_date)

Copy a NetCDF file, keeping only time steps within [start_date, end_date].
All data is read/written as raw values (no CF decoding) to avoid
DiskArrays issues with scalar and time variables.
"""
function subset_nc_by_time(src::String, dst::String, start_date::Date, end_date::Date)
    NCDataset(src, "r") do ds_in
        dates = time_var_to_dates(ds_in)
        time_idxs = findall(start_date .<= dates .<= end_date)

        if isempty(time_idxs)
            @warn "No time steps in $src within $start_date to $end_date, skipping"
            return false
        end

        NCDataset(dst, "c") do ds_out
            for (k, v) in ds_in.attrib
                ds_out.attrib[k] = v
            end

            for (dname, dlen) in ds_in.dim
                if dname == "time"
                    defDim(ds_out, dname, length(time_idxs))
                else
                    defDim(ds_out, dname, dlen)
                end
            end

            for vname in keys(ds_in)
                v = NCDatasets.variable(ds_in, vname)   # raw Variable
                dims = dimnames(v)
                attribs = v.attrib
                nd = ndims(v)

                if nd == 0
                    # scalar variable (e.g. base_time, z10, z2)
                    defVar(ds_out, vname, v[1], tuple(dims...); attrib = attribs)
                elseif "time" in dims
                    idxs = ntuple(nd) do i
                        dims[i] == "time" ? time_idxs : Colon()
                    end
                    defVar(ds_out, vname, v[idxs...], tuple(dims...); attrib = attribs)
                else
                    defVar(ds_out, vname, Array(v), tuple(dims...); attrib = attribs)
                end
            end
        end
    end
    return true
end

# ARM daily files are named like `product.YYYYMMDD.HHMMSS.ext`
# (e.g. `sgpinterpolatedsondeC1.c1.20100918.000030.nc`).
const ARM_DAILY_DATE_REGEX = r"\.(\d{8})\.\d{6}\."

"""
    copy_daily_files(src_dir, dst_dir, start_date, end_date)

Copy daily ARM files whose date (parsed from the filename) is within
[start_date, end_date].
"""
function copy_daily_files(
    src_dir::String,
    dst_dir::String,
    start_date::Date,
    end_date::Date,
)
    copied = 0
    for f in readdir(src_dir)
        m = match(ARM_DAILY_DATE_REGEX, f)
        m === nothing && continue
        file_date = try
            Date(m[1], dateformat"yyyymmdd")
        catch
            @info "Cannot process (unparseable date), skipping" file = f
            continue
        end
        if start_date <= file_date <= end_date
            cp(joinpath(src_dir, f), joinpath(dst_dir, f); force = true)
            copied += 1
        end
    end
    @info "Copied $copied files from $(basename(src_dir)) for $start_date to $end_date"
    return copied
end
