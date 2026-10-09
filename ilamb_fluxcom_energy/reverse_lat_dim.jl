using NCDatasets

"""
    reverse_lat_dim(file_path, var_name)

Reverse the latitude dimension (and the data and latitude bounds along this
axis) for the .nc file at `file_path`, for the variable `var_name`. This is
needed for FLUXCOM files from https://www.ilamb.org/ILAMB-Data/DATA/, where the
latitude dimension is in decreasing order.
"""
function reverse_lat_dim(file_path, var_name)
    ds = NCDataset(file_path, "a")
    ds["lat"][:] = reverse(Array(ds["lat"]))
    ds["lat_bnds"][:, :] = reverse(Array(ds["lat_bnds"]), dims = 2)
    ds[var_name][:, :, :] = reverse(Array(ds[var_name]), dims = 2)
    close(ds)
end

hfls_reverse_dim() = reverse_lat_dim("hfls.nc", "hfls")
hfss_reverse_dim() = reverse_lat_dim("hfss.nc", "hfss")
