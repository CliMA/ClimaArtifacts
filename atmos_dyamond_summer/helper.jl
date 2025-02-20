
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

function interpz_3d(target_z, z3d, var3d)
    nx, ny, nz = size(z3d)
    nztarget = length(target_z)
    # flip dimensions from (nx, ny, nz) to (nz, nx, ny)
    target_var3d = similar(var3d, nztarget, nx, ny)
    target_z3 = repeat(target_z, 1, nx, ny)
    z3d_permuted = permutedims(z3d, (3, 1, 2))
    var3d_permuted = permutedims(var3d, (3, 1, 2))
    interpolate1d!(target_var3d, z3d_permuted, target_z3, var3d_permuted, Linear(), Flat())
    return permutedims(target_var3d, (2, 3, 1))
end
