using NCDatasets

"""
    reverse_lat_dim(file_path, var_name)

Reverse the latitude dimension (and the data along this axis) for the .nc file at
`file_path`, for the variable `var_name`. This is needed for FLUXCOM files from
https://www.ilamb.org/ILAMB-Data/DATA/, where the latitude dimension is in
decreasing order.
"""
function reverse_lat_dim(file_path, var_name)
    ds = NCDataset(file_path, "a")
    dslat = reverse(Array(ds["lat"]))
    dsvar = reverse(Array(ds[var_name]), dims = 2)
    ds["lat"][:] = dslat
    ds[var_name][:, :, :] = dsvar
    close(ds)
end

reco_reverse_dim() = reverse_lat_dim("reco.nc", "reco")
nee_reverse_dim() = reverse_lat_dim("nee.nc", "nee")
