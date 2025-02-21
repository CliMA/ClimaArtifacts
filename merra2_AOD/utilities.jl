using NCDatasets
using Dates

"""
    test_AOD_ds(ds)

Test that the dataset `ds` has the correct structure and values for the AOD dataset.
"""
function test_AOD_ds(ds)
    for (varname, var) in ds
        @assert all(.!ismissing.(var[:]))
        if eltype(var[:]) <: Union{Missing,Number}
            @assert all(.!isnan.(var[:]))
            @assert all(.!isinf.(var[:]))
            if !(varname in ["lat", "lon", "time"])
                @assert all(0.0 .<= var[:])
            end
        end
        if varname == "time"
            @assert all(Day(28) .<= diff(var[:]) .<= Day(31))
        end
    end


    for aerosol in ["TOT", "BC", "DU", "OC", "SS"]
        @assert all(ds[aerosol*"SCATAU"][:] .<= ds[aerosol*"EXTTAU"][:]) aerosol
        if !(aerosol == "TOT" || aerosol == "SU")
            @assert all(0.0 .<= ds[aerosol*"CMASS"][:])
        end
    end
    # Note that "SUSCATAU" is greater than "SUEXTTAU" at some points
    for var in ["SO4CMASS", "SUSCATAU", "SUEXTTAU"]
        @assert all(0.0 .<= ds[var][:])
    end
end

function thin_AOD_ds!(ds_small, ds, thinning_factor)

    defDim(ds_small, "lon", Int(ceil(ds.dim["lon"] // THINNING_FACTOR)))
    defDim(ds_small, "lat", Int(ceil(ds.dim["lat"] // THINNING_FACTOR)))
    defDim(ds_small, "t", ds.dim["time"])

    lon = defVar(ds_small, "lon", Float32, ("lon",), attrib = ds["lon"].attrib)
    lon[:] = ds["lon"][:][begin:THINNING_FACTOR:end]
    lat = defVar(ds_small, "lat", Float32, ("lat",), attrib = ds["lat"].attrib)
    lat[:] = ds["lat"][:][begin:THINNING_FACTOR:end]
    time = defVar(ds_small, "time", ds[:time][:], ("time",), attrib = ds["time"].attrib)
    for (varname, var) in ds
        if !(varname in ["lat", "lon", "time"])
            defVar(ds_small, varname, Float32, dimnames(var), attrib = var.attrib)
            ds_small[varname][:, :, :] =
                var[begin:THINNING_FACTOR:end, begin:THINNING_FACTOR:end, :]
        end
    end
end

function ds_copyto!(ds_dest, ds_src)
    for (d, n) in ds_src.dim
        defDim(ds_dest, d, n)
    end
    for (varname, var) in ds_src
        if varname in ["lat", "lon", "time"]
            defVar(ds_dest, varname, Float32, (varname,), attrib = var.attrib)
            if varname == "time"
                ds_dest[varname][:] = var[:] .+ Dates.Day(14)
            else
                ds_dest[varname][:] = var[:]
            end
        else
            defVar(ds_dest, varname, Float32, dimnames(var), attrib = var.attrib)
            if ds_dest[varname].attrib["units"] == "1"
                ds_dest[varname].attrib["units"] = ""
            end
            ds_dest[varname][:, :, :] = var[:, :, :]
        end
    end
end
