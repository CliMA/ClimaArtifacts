"""
    regrid(data, (lon, lat), resolution, transform, nlayers)

Regrids `data` to the resolution specified, returns the regridded data.

This function takes `data` (size (nlon, nlat, nlayers)) defined at the points specified by the arrays of `lon` (length nlon) and `lat` (length nlat), 
as well as a desired `resolution` in degrees. The resolution should
correspond to grid cells larger than 1kmx1km (the resolution of `data`).

For each coarse grid cell, the mean over the data in that cell is
taken, ignoring points in lakes or oceans. The function `transform`
is then applied to the mean.

No regridding in depth is carried out.
"""
function regrid(data, (lon, lat), resolution, transform, nlayers)
    (lat_min, lat_max) = extrema(lat)
    (lon_min, lon_max) = extrema(lon)

    lat_count = Int(ceil((lat_max - lat_min) / resolution)) + 1
    lon_count = Int(ceil((lon_max - lon_min) / resolution)) + 1
    
    outdata = zeros(Float32, lon_count, lat_count, nlayers)

    for lat_id in 1:1:lat_count
        for lon_id in 1:1:lon_count
            lat_mask =
                (lat .>= lat_min + resolution * (lat_id - 1)) .&
                (lat .< lat_min + resolution * lat_id)
            lon_mask =
                (lon .>= lon_min + resolution * (lon_id - 1)) .&
                (lon .< lon_min + resolution * lon_id)
            x = data[lon_mask, lat_mask, :]
            # If `x` is Missing, we are over the ocean, and not over the land.
            # Here we make a land mask by checking where x is *not* Missing.
            x_land_mask = .!ismissing.(x)
            if sum(x_land_mask) / prod(size(x)) > 0.5 # count as land
                m = [mean(skipmissing(x[:, :, k])) for k in 1:nlayers]
                outdata[lon_id, lat_id, :] .= transform.(m)
            else
                outdata[lon_id, lat_id, :] .= 0f0 # all set to zero
            end

        end
    end
    return outdata,
        range(stop = lat_max, step = resolution, length = lat_count),
        range(stop = lon_max, step = resolution, length = lon_count)
end

function read_nc_data!(data, files, filedir)
    for layer in 1:nlayers
        @show(layer)
        filepath = joinpath(filedir, files[layer])
        nc_data = NCDatasets.NCDataset(filepath)
        data[:, :, layer] .= nc_data["Band1"][:,:];
    end
end

function write_nc_out(outdata, outlat, outlon, outz, attrib, outfilepath)
    (vartitle, varunits, varname) = attrib
    ds = NCDataset(outfilepath, "c")
    defDim(ds, "lon", size(outdata)[1])
    defDim(ds, "lat", size(outdata)[2])
    defDim(ds, "z", nlayers)
    ds.attrib["title"] = vartitle

    la = defVar(ds, "lat", Float32, ("lat",))
    lo = defVar(ds, "lon", Float32, ("lon",))
    zv = defVar(ds, "z", Float32, ("z",))
    var = defVar(ds, varname, Float32, ("lon", "lat", "z"))
    var.attrib["units"] = varunits
    la.attrib["units"] = "degrees_north"
    la.attrib["standard_name"] = "latitude"
    lo.attrib["standard_name"] = "longitude"
    lo.attrib["units"] = "degrees_east"
    zv.attrib["standard_name"] = "depth"
    zv.attrib["units"] = "m"

    la[:] = outlat
    lo[:] = outlon
    zv[:] = z
    var[:, :, :] = outdata
    close(ds)
end
