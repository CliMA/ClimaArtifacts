# The GriddingMachine MODIS LAI at 0.05° averages the water part of each pixel
# as LAI = 0 (and then stores LAI = 0 as NaN), so a coastal pixel holds about
# `land fraction × LAI of its land part`. These functions aggregate the 0.05°
# pixels to coarser cells over the land only. See the README for details.

"""
Smallest land fraction given to a pixel that MODIS sees as vegetated. The MODIS
and ETOPO coastlines differ by up to a pixel, and dividing by the ETOPO land
fraction of such a pixel blows up on small islands.
"""
const VEGETATED_LAND_FRACTION_MIN = 0.5f0

"""
ERA5 land fraction below which a pixel without vegetation in any month of any
year is taken as a lake (the ETOPO land-sea mask counts lakes as land).
"""
const LAKE_ERA5_LAND_FRACTION_MAX = 0.5f0

"""
ERA5 land fraction above which a vegetated pixel that the ETOPO mask sees as
mostly water is taken as land: the ETOPO mask floods land below sea level that
connects to the sea, such as the Dutch polders. The LAI of these pixels matches
that of their fully-land neighbors, while vegetated pixels with a lower ERA5
land fraction are diluted as the ETOPO land fraction predicts.
"""
const FLOODED_ERA5_LAND_FRACTION_MIN = 0.9f0

"""
    block_mean(A, n)

Mean of `A` over blocks of `n × n` cells.
"""
function block_mean(A, n)
    nI, nJ = size(A, 1) ÷ n, size(A, 2) ÷ n
    out = zeros(Float32, nI, nJ)
    for J in 1:nJ, I in 1:nI
        s = 0.0
        for j in ((J - 1) * n + 1):(J * n), i in ((I - 1) * n + 1):(I * n)
            s += A[i, j]
        end
        out[I, J] = s / n^2
    end
    return out
end

"""
    block_sum(A, n)

Sum of `A` over blocks of `n × n` cells in the first two dimensions.
"""
function block_sum(A::AbstractArray{T, 3}, n) where {T}
    n == 1 && return copy(A)
    nI, nJ, nt = size(A, 1) ÷ n, size(A, 2) ÷ n, size(A, 3)
    out = zeros(T, nI, nJ, nt)
    for t in 1:nt, J in 1:nJ, I in 1:nI
        s = zero(Float64)
        for j in ((J - 1) * n + 1):(J * n), i in ((I - 1) * n + 1):(I * n)
            s += A[i, j, t]
        end
        out[I, J, t] = s
    end
    return out
end
block_sum(A::AbstractMatrix, n) = dropdims(block_sum(reshape(A, size(A)..., 1), n); dims = 3)

"""
    weighted_block_sum!(out, A, weight, n)

Store in `out` the sum of `weight[j] * A[i, j]` over blocks of `n × n` pixels,
where `weight[j]` is the relative area of a pixel in row `j`. NaN counts as 0.
"""
function weighted_block_sum!(out, A, weight, n)
    for J in axes(out, 2), I in axes(out, 1)
        s = 0.0
        for j in ((J - 1) * n + 1):(J * n)
            sj = 0.0
            for i in ((I - 1) * n + 1):(I * n)
                v = A[i, j]
                isnan(v) || (sj += v)
            end
            s += weight[j] * sj
        end
        out[I, J] = s
    end
    return out
end

"""
    nearest_node_values(field, lon, lat)

Sample `field`, given on 0.1° nodes (longitude 0, 0.1, ..., 359.9 and latitude
-90, -89.9, ..., 90), at the nodes nearest to the pixel centers `lon` × `lat`.
"""
function nearest_node_values(field, lon, lat)
    @assert size(field) == (3600, 1801)
    return Float32[
        field[mod(round(Int, 10 * mod(x, 360)), 3600) + 1, round(Int, 10 * (y + 90)) + 1]
        for x in lon, y in lat
    ]
end

"""
    pixel_weights(f_etopo, era5_land_fraction, vegetated)

Return `(f_land, f_weight)` for each 0.05° pixel:
- `f_land`: ETOPO land fraction, with lakes removed and land below sea level
  added. A lake is a pixel without vegetation in any month of any year where
  ERA5 sees water; land below sea level is a vegetated pixel that ETOPO sees as
  mostly water and ERA5 as land.
- `f_weight`: land fraction used to divide the LAI sums, i.e. `f_land` raised
  to `VEGETATED_LAND_FRACTION_MIN` for pixels that MODIS sees as vegetated.
"""
function pixel_weights(f_etopo, era5_land_fraction, vegetated)
    lake = .!vegetated .& (f_etopo .> 0) .& (era5_land_fraction .< LAKE_ERA5_LAND_FRACTION_MAX)
    flooded = vegetated .& (f_etopo .< 0.5f0) .& (era5_land_fraction .>= FLOODED_ERA5_LAND_FRACTION_MIN)
    f_land = ifelse.(lake, 0.0f0, ifelse.(flooded, 1.0f0, f_etopo))
    f_weight = ifelse.(vegetated, max.(f_land, VEGETATED_LAND_FRACTION_MIN), f_land)
    return f_land, f_weight
end

"""
    land_lai(lai_sum, land_sum, etopo_land_sum)

LAI of the land part of each cell from the sums over its pixels of `area × LAI`
(`lai_sum[lon, lat, month]`), of `area × f_weight` (`land_sum`), and of
`area × ETOPO land fraction` (`etopo_land_sum`):
- cells with land: `lai_sum / land_sum`;
- cells whose only land is lakes: 0;
- ocean cells: extended from the nearest cells, one ring at a time, so that
  interpolating near a coastline never samples water.
"""
function land_lai(lai_sum, land_sum, etopo_land_sum)
    lai = similar(lai_sum)
    for J in axes(lai, 2), I in axes(lai, 1)
        if land_sum[I, J] > 0
            lai[I, J, :] .= view(lai_sum, I, J, :) ./ land_sum[I, J]
        else
            @assert all(iszero, view(lai_sum, I, J, :))
            lai[I, J, :] .= etopo_land_sum[I, J] > 0 ? 0 : NaN
        end
    end
    return fill_rings!(lai)
end

"""
    fill_rings!(lai)

Fill the NaN cells of `lai[lon, lat, month]` one ring at a time: every NaN cell
next to a filled cell (8 neighbors, periodic in longitude) takes the mean of
its filled neighbors.
"""
function fill_rings!(lai)
    nI, nJ, nt = size(lai)
    filled = .!isnan.(view(lai, :, :, 1))
    neighbors(I, J) = (
        (mod1(I + a, nI), J + b) for a in -1:1, b in -1:1 if
        (a, b) != (0, 0) && 1 <= J + b <= nJ
    )
    frontier = Set(
        CartesianIndex(I, J) for J in 1:nJ, I in 1:nI if
        !filled[I, J] && any(filled[i, j] for (i, j) in neighbors(I, J))
    )
    while !isempty(frontier)
        ring = collect(frontier)
        for c in ring, t in 1:nt
            s, n = 0.0, 0
            for (i, j) in neighbors(c[1], c[2])
                filled[i, j] && (s += lai[i, j, t]; n += 1)
            end
            lai[c, t] = s / n
        end
        filled[ring] .= true
        empty!(frontier)
        for c in ring, (i, j) in neighbors(c[1], c[2])
            filled[i, j] || push!(frontier, CartesianIndex(i, j))
        end
    end
    return lai
end
