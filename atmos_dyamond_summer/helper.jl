
# compute pressure = hya + hyb * surface_pressure
function compute_source_pressure(surface_pressure, hya, hyb)
    nlon, nlat = size(surface_pressure)
    nz = length(hya)
    @assert length(hya) == length(hyb)
    FT = eltype(hya)
    pressure = Array{FT}(undef, nlon, nlat, nz)
    for iz in 1:nz, ilat in 1:nlat, ilon in 1:nlon
        pressure[ilon, ilat, iz] = hya[iz] + hyb[iz] * surface_pressure[ilon, ilat]
    end
    return pressure
end

# compute altitude at cell faces
function compute_z_face(p_c, p_f, t_c, q_tot_c, z_surface)
    FT = eltype(p_c)
    nlon, nlat, nz_c = size(p_c)
    nz_f = nz_c + 1
    z_f = zeros(FT, nlon, nlat, nz_f) # allocation for face z
    z_f[:, :, 1] .= z_surface

    for ilat in 1:nlat, ilon in 1:nlon
        for izc in 1:nz_c
            dp = p_f[ilon, ilat, izc + 1] - p_f[ilon, ilat, izc]
            (Rm, _, _, _) = TD.gas_constants(params, TD.PhasePartition(q_tot_c[ilon, ilat, izc]))
            cval = -(Rm * t_c[ilon, ilat, izc]) / (p_c[ilon, ilat, izc] * grav)
            z_f[ilon, ilat, izc + 1] = z_f[ilon, ilat, izc] + (cval * dp)
        end
    end

    return z_f
end

# compute altitude at cell center
function compute_z_center(z_face)
    nlon, nlat, nfaces = size(z_face)
    ncenter = nfaces - 1
    z_center = similar(z_face, nlon, nlat, ncenter)
    for ilat in 1:nlat, ilon in 1:nlon
        for izc in 1:ncenter
            z_center[ilon, ilat, izc] = (z_face[ilon, ilat, izc] + z_face[ilon, ilat, izc + 1]) * 0.5
        end
    end
    return z_center
end

function interpz_3d(ztarget, zsource, fsource)
    nx, ny, nz = size(zsource)
    # permute dimensions from (nx, ny, nz) to (nz, nx, ny) if needed
    ztargetp = ndims(ztarget) == 1 ? ztarget : permutedims(ztarget, (3, 1, 2))
    zsourcep = ndims(zsource) == 1 ? zsource : permutedims(zsource, (3, 1, 2))
    fsourcep = ndims(fsource) == 1 ? fsource : permutedims(fsource, (3, 1, 2)) 
    ftargetp = similar(fsourcep, size(ztargetp, 1), nx, ny)
    # interpolate
    interpolate1d!(ftargetp, zsourcep, ztargetp, fsourcep, Linear(), Flat())
    # permute interpolated data to initial ordering
    return permutedims(ftargetp, (2, 3, 1))
end
