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
    lat_count = Int(floor((90.0 - (-90.0)) / resolution)) + 1 # how many points we want in the model
    lon_count = Int(floor((180.0 - (-180.0)) / resolution)) + 1 # how many points we want in the model
    outdata = zeros(Float32, lon_count, lat_count, nlayers)

    lat_min = -90.0
    lon_min = -180.0
    for lat_id in 1:1:lat_count
        for lon_id in 1:1:lon_count
            lat_mask =
                (lat .>= lat_min + resolution * (lat_id - 1)) .&
                (lat .< lat_min + resolution * lat_id)
            lon_mask =
                (lon .>= lon_min + resolution * (lon_id - 1)) .&
                (lon .< lon_min + resolution * lon_id)
            x = data[lon_mask, lat_mask, :]
            x_land_mask = x .!== -3.4f38
            if sum(x_land_mask) / prod(size(x)) > 0.5 # count as land
                outdata[lon_id, lat_id, :] .= transform(mean(x[x_land_mask]))
            else
                nothing # all set to zero
            end

        end
    end
    return outdata,
    range(stop = 90.0, step = resolution, length = lat_count),
    range(stop = 180.0, step = resolution, length = lon_count)
end

function read_tif_data!(data, files, filedir)
    for i in 1:nlayers
        @show(i)
        filepath = joinpath(filedir, files[i])
        img = TiffImages.load(filepath)
        data[:, :, i] .= transpose(getfield.(img, 1))
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
