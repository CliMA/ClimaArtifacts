using NCDatasets
using Dates
using Interpolations
using ProgressMeter
using Statistics

const H_EARTH = 7000.0
const P0 = 1e5
const NUM_Z = 42

Plvl(z) = P0 * exp(-z / H_EARTH)
Plvl_inv(P) = -H_EARTH * log(P / P0)

# Aerosol names are converted to follow those in ../aerosol_concentrations
const aerosol_names = Dict(
    "BCPHOBIC" => "CB1",
    "BCPHILIC" => "CB2",
    "DU001" => "DST01",
    "DU002" => "DST02",
    "DU003" => "DST03",
    "DU004" => "DST04",
    "DU005" => "DST05",
    "OCPHOBIC" => "OC1",
    "OCPHILIC" => "OC2",
    "SO4" => "SO4",
    "SS001" => "SSLT01",
    "SS002" => "SSLT02",
    "SS003" => "SSLT03",
    "SS004" => "SSLT04",
    "SS005" => "SSLT05",
)

"""
    check_ds(path)

Check that the dataset at `path` does not contain any NaNs, Infs, or missing values, that
`z` is positive, that `z` and `time` are increasing, and that all expected data variables
are in the dataset.
"""
function check_ds(path)
    ds = NCDataset(path)
    as_expected = true
    for (varname, var) in ds
        as_expected &= all(.!ismissing.(var[:]))
        if eltype(var[:]) <: Union{Missing,Number}
            as_expected &= all(.!isnan.(var[:]))
            as_expected &= all(.!isinf.(var[:]))
            if !(varname in ["lat", "lon", "time", "z_sfc"])
                as_expected &= all(var[:] .>= 0.0)
            end
        end
        if varname == "time"
            as_expected &= all(Day(28) .<= diff(var[:]) .<= Day(31))
        end
        if varname == "z"
            as_expected &= all(0 .< diff(var[:]))
        end
    end
    ds_keys = keys(ds)
    as_expected &= all(map(x -> x in ds_keys, values(aerosol_names)))
    close(ds)
    as_expected || @warn "Dataset at $path does not meet expectations"
    return as_expected
end


# function adapted from ../aerosol_concentrations/create_artifact.jl
"""
    create_monthly_mean_ds(infile_paths, outfile_path, target_z; small = false)

Create a monthly mean dataset from daily data. The daily datasets are interpolated to the
`target_z` levels and then averaged.
"""
function create_monthly_mean_ds(infile_paths, outfile_path, target_z, surface_z; small = false)
    isfile(outfile_path) && rm(outfile_path)
    FT = Float32
    THINNING_FACTOR = 1
    ds_agg = NCDataset(infile_paths, "r"; aggdim = "time")
    ds_out = NCDataset(outfile_path, "c")
    if small
        THINNING_FACTOR = 6
        target_z = vcat(target_z[begin:THINNING_FACTOR:end], [target_z[end]])
    end

    defDim(ds_out, "lon", Int(ceil(length(ds_agg["lon"]) // THINNING_FACTOR)))
    defDim(ds_out, "lat", Int(ceil(length(ds_agg["lat"]) // THINNING_FACTOR)))
    defDim(ds_out, "z", length(target_z))
    defDim(ds_out, "time", 1)

    lon = defVar(ds_out, "lon", FT, ("lon",), attrib = ds_agg["lon"].attrib)
    lon[:] = Array(ds_agg["lon"])[begin:THINNING_FACTOR:end]

    lat = defVar(ds_out, "lat", FT, ("lat",), attrib = ds_agg["lat"].attrib)
    lat[:] = Array(ds_agg["lat"])[begin:THINNING_FACTOR:end]

    z = defVar(ds_out, "z", FT, ("z",))
    z[:] = Array(target_z)
    z.attrib["long_name"] = "altitude"
    z.attrib["units"] = "meters"
    # assume the first time is the first of the month
    defVar(
        ds_out,
        "time",
        [ds_agg["time"][1] + Day(14)],
        ("time",),
        attrib = ds_agg["time"].attrib,
    )
    n_levels = ds_agg.dim["lev"]
    n_lats = ds_out.dim["lat"]
    n_lons = ds_out.dim["lon"]
    n_times = ds_agg.dim["time"]

    zcenters = zeros(FT, n_lons, n_lats, n_levels, n_times)

    for t = 1:n_times
        day_dp =
            ds_agg["DELP"][begin:THINNING_FACTOR:end, begin:THINNING_FACTOR:end, :, t]
        day_rho = ds_agg["AIRDENS"][begin:THINNING_FACTOR:end, begin:THINNING_FACTOR:end, :, t]
        day_dz = day_dp ./ (day_rho .* 9.8)


        zcenters[:,:,end,t] .= day_dz[:,:,end] ./ 2 .+ surface_z[begin:THINNING_FACTOR:end, begin:THINNING_FACTOR:end,]
        for lev = n_levels-1:-1:1
            zcenters[:,:,lev,t] .= zcenters[:,:,lev+1,t] .+ (day_dz[:,:,lev] ./ 2) .+ (day_dz[:,:,lev+1] ./ 2)
        end
    end
    interpolated_var = zeros(
        FT,
        (ds_out.dim["lon"], ds_out.dim["lat"], length(target_z), ds_agg.dim["time"]),
    )
    defVar(
            ds_out,
            "z_sfc",
            surface_z[begin:THINNING_FACTOR:end, begin:THINNING_FACTOR:end],
            ("lon", "lat"),
    )
    for (old_varname, new_varname) in aerosol_names
        old_var = ds_agg[old_varname]
        new_var = defVar(
            ds_out,
            new_varname,
            Float32,
            Tuple([dim == "lev" ? "z" : dim for dim in dimnames(old_var)]),
            attrib = old_var.attrib,
        )
        for t = 1:n_times
            old_data = ds_agg[old_varname][
                begin:THINNING_FACTOR:end,
                begin:THINNING_FACTOR:end,
                :,
                t,
            ]
            for j = 1:n_lats
                for i = 1:n_lons

                    itp = extrapolate(
                        interpolate(
                            (reverse(zcenters[i, j, :, t]),),
                            reverse(old_data[i, j, :]),
                            Gridded(Linear()),
                        ),
                        Flat(),
                    )
                    @. interpolated_var[i, j, :, t] = itp(target_z)

                end
            end
        end
        new_var .= mean(interpolated_var, dims = 4)
    end
    interpolated_var = nothing
    close(ds_agg)
    close(ds_out)
    GC.gc()
end

"""
    get_data_for_month(month)

Return a list of file paths for the daily data for the input Date `month`. `month` is assumed
to be the first day of the month.
"""
function get_data_for_month(month)
    file_paths = Vector{String}()
    for day_offset = 1:Dates.daysinmonth(month)
        date = month + Day(day_offset - 1)
        fpath = joinpath(DATADIR, "daily_data", "$(date).nc")
        if isfile(fpath)
            push!(file_paths, fpath)
        else
            @warn "File not found: $fpath)"
        end
    end
    return file_paths
end

"""
    processing_completed(month, year; thinned=false)

Check if the processing for the input month and year is completed correctly.
"""
function processing_completed(month, year; thinned = false)
    min_file_size_mb = thinned ? 0.5 : 99
    folder = thinned ? "monthly_data_thinned" : "monthly_data"
    month_path = joinpath(DATADIR, folder, "$(year)_$(month).nc")
    return isfile(month_path) &&
           filesize(month_path) / 10^6 > min_file_size_mb &&
           check_ds(month_path)
end

"""
    get_data_for_year(start_year, end_year; small=false)

Return a list of file paths for the monthly data for the input years.
"""
function get_data_for_years(start_year, end_year; small = false)
    file_paths = Vector{String}()
    for year = start_year:end_year
        for month = 1:12
            if small
                fpath = joinpath(DATADIR, "monthly_data_thinned", "$(year)_$(month).nc")
            else
                fpath = joinpath(DATADIR, "monthly_data", "$(year)_$(month).nc")
            end
            if isfile(fpath)
                push!(file_paths, fpath)
            else
                @warn "File not found: $fpath"
            end
        end
    end
    return file_paths
end

function merge_ds(file_paths, outfile_path)
    isfile(outfile_path) && rm(outfile_path)
    ds_out = NCDataset(outfile_path, "c")
    ds_agg = NCDataset(file_paths, "r"; aggdim = "time")
    for (d, n) in ds_agg.dim
        defDim(ds_out, d, n)
    end
    @showprogress for (varname, var) in ds_agg
        if varname in ["lat", "lon", "z", "time"]
            defVar(ds_out, varname, Float32, (varname,), attrib = var.attrib)
            ds_out[varname][:] = Array(var)
        elseif varname == "z_sfc"
            defVar(ds_out, varname, Float32, ("lon", "lat"), attrib = var.attrib)
            ds_out[varname][:, :] = var[:, :, 1]
        else
            defVar(ds_out, varname, Float32, dimnames(var), attrib = var.attrib)
            for i = 1:ds_agg.dim["time"]
                ds_out[varname][:, :, :, i] = var[:, :, :, i]
            end
        end
    end
    close(ds_agg)
    close(ds_out)
end
