using NCDatasets

"""
    gpp_reverse_dim()

Reverse the dimensions for .nc file located at
https://www.ilamb.org/ILAMB-Data/DATA/gpp/FLUXCOM/gpp.nc because the latitude dimension is
in decreasing order.
"""
function gpp_reverse_dim()
    ds = NCDataset("gpp.nc", "a")
    dslat = reverse(Array(ds["lat"]))
    dsgpp = reverse(Array(ds["gpp"]), dims = 2)
    ds["lat"][:] = dslat
    ds["gpp"][:, :, :] = dsgpp
    close(ds)
end
