"""
    regrid_and_compute_statistic(data, (lon, lat), resolution, statistics)

Regrids `data` to the resolution specified by computing statistics of interest
over all data points in the simulation grid boxes of size resolution.

This function takes `data` (size (nlon, nlat)) defined at the points specified by the arrays of `lon` (length nlon) and `lat` (length nlat), 
as well as a desired `resolution` in degrees. The resolution should
correspond to grid cells larger than 1kmx1km (the resolution of `data`).

For each coarse grid cell, the statistics are computed over the data in that cell,
ignoring points in lakes or oceans.

They must be a function of the form x::AbstractArray - > f(x)::Float.
"""
function regrid_and_compute_statistics(data, (lon, lat), resolution, statistics)
    (lat_min, lat_max) = extrema(lat)
    (lon_min, lon_max) = extrema(lon)

    lat_count = Int(ceil((lat_max - lat_min) / resolution)) + 1
    lon_count = Int(ceil((lon_max - lon_min) / resolution)) + 1

    lat_grid = range(stop = lat_max, step = resolution, length = lat_count)
    lon_grid = range(stop = lon_max, step = resolution, length = lon_count)
    
    n_stats = length(statistics)
    outdata = zeros(Float32, lon_count, lat_count, n_stats)

    # Preallocation speeds things up a bit
    lat_mask = BitArray(zeros(size(lat)));
    lon_mask = BitArray(zeros(size(lon)));
    
    for (lat_id, lat_val) in enumerate(lat_grid)
        for (lon_id, lon_val) in enumerate(lon_grid)
            @show lat_id/lat_count
            lat_mask .= (lat .>= lat_val) .& (lat .< lat_val + resolution)
            lon_mask .= (lon .>= lon_val) .& (lon .< lon_val + resolution)
            
            x = data[lon_mask, lat_mask];
            # If `x` is Missing, we are over the ocean, and not over the land.
            # Here we make a land mask by checking where x is *not* Missing.
            x_land_mask = .!ismissing.(x)
            
            if sum(x_land_mask) / prod(size(x)) > 0.5 # count as land
                for (i, stat) in enumerate(statistics)
                    outdata[lon_id, lat_id, i] = stat(x[x_land_mask])
                end
            else
                outdata[lon_id, lat_id, :] .= 0f0 # all set to zero
            end

        end
    end
    return outdata, lat_grid, lon_grid
end

"""
    write_nc_out(outdata, outlat, outlon, attribs, outfile_path)

Takes the compute statistics array `outdata`, of size nlon, nlat, nstats,
with corresponding values of lon and lat of `outlat`, `outlon`, and the attributes
for the nc data, and saves the data in NetCDF format to outfile_path
"""
function write_nc_out(outdata, outlat, outlon, attribs, outfile_path)
    global_attrib = attribs.global_attrib
    curr_history = global_attrib["history"]
    new_history =
        curr_history *
        "; Modified by CliMA for use in ClimaLand models (see topmodel folder in ClimaArtifacts for full changes). Contains
data supplied by Natural Environment Research Council."
    global_attrib["history"] = new_history

    ds = NCDataset(outfile_path, "c",attrib = global_attrib)
    defDim(ds, "lon", size(outdata)[1])
    defDim(ds, "lat", size(outdata)[2])


    la = defVar(ds, "lat", Float32, ("lat",))
    lo = defVar(ds, "lon", Float32, ("lon",))
    la.attrib["units"] = "degrees_north"
    la.attrib["standard_name"] = "latitude"
    lo.attrib["standard_name"] = "longitude"
    lo.attrib["units"] = "degrees_east"
    
    la[:] = outlat
    lo[:] = outlon
    
    for (i,attrib) in enumerate(attribs.var_attribs)
        (varlongname, varunits, varname) = attrib
        var = defVar(ds, varname, Float32, ("lon", "lat"))
        var.attrib["units"] = varunits
        var.attrib["standard_name"] = varname
        var.attrib["long_name"] = varlongname
        var[:, :] = outdata[:,:,i]
    end
    
    close(ds)
end
