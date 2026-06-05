replace_missing_with_zero_transform_nonzero(x; transform) = ismissing(x)  ? 0f0 : transform(x)

"""
    thin_data(data, (lon, lat), transform, thin_factor, nlayers)

Thins `data` using the thin_factor specified, returns the thinned data, after applying the transform

This function takes `data` (size (nlon, nlat, nlayers)) defined at the points specified by the arrays of `lon` (length nlon) and `lat` (length nlat).
"""
function thin_data(data, (lon, lat), transform, thin_factor, nlayers)
    new_lat = lat[1:thin_factor:end]
    new_lon = lon[1:thin_factor:end]
    
    outdata = zeros(Float32, length(new_lon), length(new_lat), nlayers)
    outdata .= replace_missing_with_zero_transform_nonzero.(data[1:thin_factor:end, 1:thin_factor:end, :]; transform)
    return outdata, new_lat, new_lon
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
