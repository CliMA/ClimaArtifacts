
# This file contains functions used in the processing of multiple datasets.

"""
    calc_sw_alb(sw_up, sw_down)

Calculate the shortwave albedo from the upwelling and downwelling shortwave radiation. If the
downwelling radiation is zero, the albedo is set to 1.0. If the ratio of upwelling to downwelling
radiation is greater than 1.0, the albedo is set to 1.0.
"""
function calc_sw_alb(sw_up::FT, sw_down::FT) where {FT<:AbstractFloat}
    sw_down == 0 && return FT(1.0)
    sw_up / sw_down <= FT(1.0) && return sw_up / sw_down
    return FT(1.0)
end

"""
    check_ds(path)

Check that the dataset at `path` does not contain any NaNs, Infs, or missing values, and
that any albedo values are between 0 and 1.
"""
function check_ds(path)
    ds = NCDataset(path)
    for (varname, var) in ds
        @assert all(.!ismissing.(var[:]))
        if eltype(var[:]) <: Number
            @assert all(.!isnan.(var[:]))
            @assert all(.!isinf.(var[:]))
            occursin("sw_alb", varname) &&
                @assert all(var[:] .>= 0.0) && all(var[:] .<= 1.0)
        end
    end
    close(ds)
end
