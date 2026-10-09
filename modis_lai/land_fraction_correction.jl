# The GriddingMachine MODIS LAI averages water pixels (ocean and inland water)
# as LAI = 0, so the LAI of a coastal or lake-side 1° cell is approximately
# `land_fraction × LAI of its land part`. These functions recover the LAI of the
# land part using the ERA5 land fraction. See the README for details.

using Statistics

# Below this land fraction, LAI / land_fraction amplifies noise and is biased
# high (the MODIS and ERA5 coastlines differ at sub-cell scale), so the cell is
# filled from its neighbours instead.
const LAND_FRACTION_MIN = 0.5

"""
    cell_land_fraction(lsm, lon_centers, lat_centers)

Average the ERA5 land fraction `lsm`, given on 0.1° nodes (longitude 0, 0.1,
..., 359.9 and latitude -90, -89.9, ..., 90), over the 1° cells centered at
`lon_centers` and `lat_centers`. Nodes on a cell edge count half.
"""
function cell_land_fraction(lsm, lon_centers, lat_centers)
    @assert size(lsm) == (3600, 1801)
    fland = zeros(length(lon_centers), length(lat_centers))
    for (j, lat_c) in enumerate(lat_centers), (i, lon_c) in enumerate(lon_centers)
        total = 0.0
        weight = 0.0
        for a in 0:10, b in 0:10
            w = (a in (0, 10) ? 0.5 : 1.0) * (b in (0, 10) ? 0.5 : 1.0)
            lon = mod(lon_c - 0.5 + 0.1a, 360)
            lat = lat_c - 0.5 + 0.1b
            ii = mod(round(Int, 10lon), 3600) + 1
            jj = round(Int, 10(lat + 90)) + 1
            total += w * lsm[ii, jj]
            weight += w
        end
        fland[i, j] = total / weight
    end
    return fland
end

"""
    neighbors(i, j, nlon, nlat)

Return the indices of the (up to 8) cells around `(i, j)`, periodic in longitude.
"""
neighbors(i, j, nlon, nlat) = [
    (mod1(i + di, nlon), j + dj) for di in -1:1, dj in -1:1 if
    (di, dj) != (0, 0) && 1 <= j + dj <= nlat
]

"""
    land_fraction_corrected(lai, fland; fland_min = LAND_FRACTION_MIN)

Return the LAI of the land part of each cell, given the cell-mean `lai[lon, lat,
month]` (water counted as LAI = 0) and the land fraction `fland[lon, lat]`:

- `fland ≥ fland_min`: `lai / fland`;
- `0 < fland < fland_min`: mean of the corrected neighbors with
  `fland ≥ fland_min`, or `lai / fland_min` if there is none (isolated islands);
- `fland = 0`: extended from the nearest land cells, so that interpolating
  near a coastline never samples water.

Values are capped at the largest LAI in `lai`, which only binds on islands whose
MODIS land area exceeds the ERA5 one.
"""
function land_fraction_corrected(lai, fland; fland_min = LAND_FRACTION_MIN)
    nlon, nlat, _ = size(lai)
    out = fill(NaN, size(lai))
    valid = fland .>= fland_min
    for j in 1:nlat, i in 1:nlon
        valid[i, j] && (out[i, j, :] .= lai[i, j, :] ./ fland[i, j])
    end
    for j in 1:nlat, i in 1:nlon
        (0 < fland[i, j] < fland_min) || continue
        nbrs = filter(c -> valid[c...], neighbors(i, j, nlon, nlat))
        out[i, j, :] .=
            isempty(nbrs) ? lai[i, j, :] ./ fland_min :
            mean(out[ii, jj, :] for (ii, jj) in nbrs)
    end
    # Grow the land values over water one ring of cells at a time
    filled = .!isnan.(out[:, :, 1])
    while !all(filled)
        front = Tuple{Int, Int, Vector{Float64}}[]
        for j in 1:nlat, i in 1:nlon
            filled[i, j] && continue
            nbrs = filter(c -> filled[c...], neighbors(i, j, nlon, nlat))
            isempty(nbrs) ||
                push!(front, (i, j, mean(out[ii, jj, :] for (ii, jj) in nbrs)))
        end
        for (i, j, value) in front
            out[i, j, :] .= value
            filled[i, j] = true
        end
    end
    return min.(out, maximum(lai))
end
