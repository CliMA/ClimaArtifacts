function read_nc_data!(data, files, filedir)
    for i in 1:nlayers
        @show(i)
        filepath = joinpath(filedir, files[i])
        nc_data = NCDatasets.NCDataset(filepath)
        data[:, :, i] .= nc_data["Band1"][:,:];
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
