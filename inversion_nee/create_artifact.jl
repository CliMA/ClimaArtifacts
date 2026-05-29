#=
create_artifact.jl

Build a NEE + GPP + ER + Rh artifact on a global 1°×1° monthly grid for
2002-01 .. 2020-12, from four open data sources:

  1. NOAA CarbonTracker CT2022, monthly 1°×1° fluxes
        https://gml.noaa.gov/aftp/products/carbontracker/co2/CT2022/fluxes/monthly/
  2. GFED5.1 monthly ecosystem C emissions (Chen et al. 2023)
        https://zenodo.org/records/16794692
  3. GOSIF-GPP v2 monthly Mean GeoTIFFs (Li & Xiao 2019)
        http://data.globalecology.unh.edu/data/GOSIF-GPP_v2/Monthly/Mean/
  4. Hashimoto 2015 global soil respiration (Hashimoto et al. 2015)
        https://zenodo.org/records/4708444

Derivations (all on the 1°×1° monthly grid):

  NEE  =  CT2022 bio_flux_opt                            (positive = source)
  GPP  =  GOSIF-GPP, regridded                           (positive = uptake)
  ER   =  NEE + GPP                                      (positive = source)
  Rh   =  Hashimoto monthly Rs × (annual Rh / annual Rs) (positive = source)

CarbonTracker's `bio_flux_opt` is the inversion-optimized biospheric flux with
fire already separated out (CT prescribes fire from GFED4.1s as `fire_flux_imp`,
which we keep as a diagnostic only). So no GFED fire subtraction is needed to
get a near-NEE quantity; the remaining contamination is LUC and lateral
fluxes, the same as for any inversion product.

Rh derivation: Hashimoto publishes monthly Rs (1901–2012) and annual Rh
(1901–2012) but no monthly Rh. We derive monthly Rh by scaling monthly Rs
by the per-pixel annual Rh/Rs ratio:
    Rh_monthly[lon,lat,y,m] = Rs_monthly[lon,lat,y,m] *
                              Rh_annual[lon,lat,y] / sum_m Rs_monthly[lon,lat,y,m]
This preserves the annual mass balance (sum_m Rh_monthly = Rh_annual) and
gives Rh seasonality from Rs seasonality (i.e., assumes Rh/Rs is constant
within a year per pixel). Hashimoto coverage ends in 2012, so 2013–2020 are
filled with the 2002–2012 monthly climatology. Rh is a *soft constraint* in
the calibration (a magnitude prior to keep modeled Rh from collapsing to 0),
not a pixel-by-pixel target.

Sign conventions throughout: NEE, ER, Rh are positive when carbon flows TO
the atmosphere; GPP is positive when carbon flows INTO the ecosystem. Rh is
guaranteed non-negative by construction; ER (= NEE + GPP) is a residual and
can be negative in pixel-months where the inversion sink exceeds GPP.

See README.md for the choices, limitations, and citations. Run with:

    julia --project=. -e 'using Pkg; Pkg.instantiate()'   # once
    julia --project=. create_artifact.jl
=#

using ArchGDAL
using CodecZlib
using Downloads
using NCDatasets
using Statistics
using Dates
using ZipFile
using ClimaArtifactsHelper

# ------------------------------------------------------------------
# Configuration
# ------------------------------------------------------------------

const YEAR_START = 2002
const YEAR_END   = 2020

# CarbonTracker CT2022 monthly 1°×1° flux files (one per month):
const CT_BASE = "https://gml.noaa.gov/aftp/products/carbontracker/co2/CT2022/fluxes/monthly"
ct_filename(y, m) = "CT2022.flux1x1.$(y)$(lpad(m, 2, '0')).nc"
ct_url(y, m)      = "$CT_BASE/$(ct_filename(y, m))"

const GFED5_URL = "https://zenodo.org/records/16794692/files/GFED5.1_ecosystem.zip?download=1"
const GFED5_ZIP = "GFED5.1_ecosystem.zip"

# GOSIF-GPP v2 monthly Mean GeoTIFFs (one file per month, gzipped):
const GOSIF_BASE   = "http://data.globalecology.unh.edu/data/GOSIF-GPP_v2/Monthly/Mean"
gosif_filename(y, m) = "GOSIF_GPP_$(y).M$(lpad(m, 2, '0'))_Mean.tif.gz"
gosif_url(y, m)      = "$GOSIF_BASE/$(gosif_filename(y, m))"

# GOSIF-GPP v2 GeoTIFFs store values as UInt16 = GPP × 100 in g C m⁻² month⁻¹.
# Per Li & Xiao 2019 Fair_Data_Use_Policy_and_Readme_GOSIF-GPP_v2.pdf:
#   Scale factor: 0.01 (monthly product)
#   Units after scaling: g C m⁻² mo⁻¹
#   Fill values: 65535 (water bodies), 65534 (lands under snow/ice year-round)
const GOSIF_SCALE     = 0.01
const GOSIF_FILL_VALS = (UInt16(65535), UInt16(65534))

# Hashimoto 2015 soil-respiration files (Zenodo 4708444).
# RS_mon: monthly total soil respiration, 1901–2012, 0.5°, gC m⁻² day⁻¹.
# RH_yr:  annual heterotrophic respiration, 1901–2012, 0.5°, gC m⁻² year⁻¹.
# Both files: lon 0..360, lat -89.75..89.75, fill -999.0, variable name `co2`.
const HASHIMOTO_RS_URL =
    "https://zenodo.org/records/4708444/files/RS_mon_Hashimoto2015.nc"
const HASHIMOTO_RH_URL =
    "https://zenodo.org/records/4708444/files/RH_yr_Hashimoto2015.nc"
const HASHIMOTO_RS_FILE = "RS_mon_Hashimoto2015.nc"
const HASHIMOTO_RH_FILE = "RH_yr_Hashimoto2015.nc"
# Hashimoto product covers 1901–2012; clip to the overlap with the inversion
# window. 2013..YEAR_END will be filled with the 2002..2012 climatology.
const HASHIMOTO_YEAR_END = 2012

const OUTPUT_FILE = "derived_nee_gpp_er_rh_$(YEAR_START)_$(YEAR_END).nc"

# Working directory for raw downloads (kept outside the artifact dir so we can
# rerun cheaply):
const RAW_DIR = joinpath(@__DIR__, "raw")
isdir(RAW_DIR) || mkdir(RAW_DIR)

# Artifact output directory (this becomes the artifact):
const OUTPUT_DIR = joinpath(@__DIR__, basename(@__DIR__) * "_artifact")
if isdir(OUTPUT_DIR)
    @warn "$OUTPUT_DIR already exists. Existing files may be overwritten."
else
    mkdir(OUTPUT_DIR)
end

# ------------------------------------------------------------------
# 1. Downloads
# ------------------------------------------------------------------

function ensure_downloaded(url, path)
    if isfile(path)
        @info "Already present: $path"
    else
        @info "Downloading $url -> $path"
        tmp = Downloads.download(url; progress = download_rate_callback())
        Base.mv(tmp, path)
    end
end

ensure_downloaded(GFED5_URL, joinpath(RAW_DIR, GFED5_ZIP))

# Hashimoto soil-respiration files (~1.5 GB total):
hashimoto_dir = joinpath(RAW_DIR, "Hashimoto")
isdir(hashimoto_dir) || mkpath(hashimoto_dir)
ensure_downloaded(HASHIMOTO_RH_URL, joinpath(hashimoto_dir, HASHIMOTO_RH_FILE))
ensure_downloaded(HASHIMOTO_RS_URL, joinpath(hashimoto_dir, HASHIMOTO_RS_FILE))

# Extract GFED5 zip if not already done. The zip unpacks one .nc per year
# directly into the destination (no inner folder).
gfed5_marker = joinpath(RAW_DIR, "GFED5.1_ecosystem_$(YEAR_START).nc")
if !isfile(gfed5_marker)
    @info "Extracting $GFED5_ZIP"
    r = ZipFile.Reader(joinpath(RAW_DIR, GFED5_ZIP))
    try
        for f in r.files
            outpath = joinpath(RAW_DIR, f.name)
            if endswith(f.name, "/")
                isdir(outpath) || mkpath(outpath)
            else
                isdir(dirname(outpath)) || mkpath(dirname(outpath))
                open(outpath, "w") do io
                    write(io, read(f))
                end
            end
        end
    finally
        close(r)
    end
end

# Download CT2022 monthly files (72 files, ~2 MB each, ~150 MB total):
ct_dir = joinpath(RAW_DIR, "CT2022")
isdir(ct_dir) || mkdir(ct_dir)
for y in YEAR_START:YEAR_END, m in 1:12
    ensure_downloaded(ct_url(y, m), joinpath(ct_dir, ct_filename(y, m)))
end

# Download GOSIF-GPP monthly Mean TIFFs (72 files, ~5–10 MB each compressed):
gosif_dir = joinpath(RAW_DIR, "GOSIF_GPP_v2_Monthly_Mean")
isdir(gosif_dir) || mkdir(gosif_dir)
for y in YEAR_START:YEAR_END, m in 1:12
    fn  = gosif_filename(y, m)
    gz  = joinpath(gosif_dir, fn)
    tif = replace(gz, ".gz" => "")
    if !isfile(tif)
        ensure_downloaded(gosif_url(y, m), gz)
        @info "Decompressing $fn"
        open(gz, "r") do compressed
            open(tif, "w") do decompressed
                write(decompressed, GzipDecompressorStream(compressed))
            end
        end
        rm(gz; force = true)   # save disk, keep the decompressed copy
    end
end

# ------------------------------------------------------------------
# 2. Read CT2022 monthly 1°×1° bio_flux_opt
#
# Each CT2022.flux1x1.YYYYMM.nc holds one timestep with:
#   bio_flux_opt    optimized biospheric flux  [mol m-2 s-1]
#   fire_flux_imp   imposed (prescribed) fire  [mol m-2 s-1]
#   ocn_flux_opt, fossil_flux_imp              [mol m-2 s-1]
# Sign convention: positive = source to atmosphere.
# We stack 72 monthly files into a (lon, lat, 72) array, converting to
# g C m^-2 month^-1.
# ------------------------------------------------------------------

const C_PER_MOL = 12.011                          # g C / mol

function read_ct2022_stack(dir; year_start = YEAR_START, year_end = YEAR_END)
    n_months = 12 * (year_end - year_start + 1)
    nee  = Array{Float64}(undef, 360, 180, n_months)
    fire = Array{Float64}(undef, 360, 180, n_months)
    times = DateTime[]
    lat = lon = nothing
    k = 0
    for y in year_start:year_end, m in 1:12
        k += 1
        path = joinpath(dir, ct_filename(y, m))
        NCDataset(path) do ds
            if lat === nothing
                lat = collect(ds["latitude"][:])
                lon = collect(ds["longitude"][:])
            end
            # Convert mol m^-2 s^-1 → g C m^-2 month^-1:
            sec_per_month = Float64(daysinmonth(Date(y, m, 1))) * 86400.0
            factor = C_PER_MOL * sec_per_month
            nee[:,  :, k] = Array(ds["bio_flux_opt"][:, :, 1]) .* factor
            fire[:, :, k] = Array(ds["fire_flux_imp"][:, :, 1]) .* factor
            push!(times, DateTime(y, m, 15))
        end
    end
    return (; lat, lon, t = times, nee, fire_ct = fire)
end

ct = read_ct2022_stack(ct_dir)
@info "CT2022 stack: $(length(ct.lon)) lon × $(length(ct.lat)) lat × $(length(ct.t)) months"

# ------------------------------------------------------------------
# 3. Read GFED5 monthly C emissions and regrid 0.25° → 1°
#
# GFED5.1 ecosystem ships one .nc per year, each with a 12-month time axis
# and variable `carbon_emissions` in g C per month on a 0.25° grid.
# We use GFED5 only as a diagnostic — NEE comes from CT2022 directly.
# ------------------------------------------------------------------

function read_gfed5(dir; year_start = YEAR_START, year_end = YEAR_END)
    lat = lon = nothing
    grid_area = nothing
    months_all = DateTime[]
    C_all = nothing
    for y in year_start:year_end
        f = joinpath(dir, "GFED5.1_ecosystem_$(y).nc")
        isfile(f) || error("Missing $f")
        NCDataset(f) do ds
            if lat === nothing
                lat = collect(ds["lat"][:])
                lon = collect(ds["lon"][:])
                grid_area = Array(ds["grid_area"][:, :])     # m² per pixel
            end
            # `carbon_emissions` is total g C per pixel per month → divide by
            # pixel area (m²) to get g C m⁻² month⁻¹:
            raw = Array(ds["carbon_emissions"][:, :, :])
            data = similar(raw, Float64)
            for k in 1:size(raw, 3)
                data[:, :, k] = raw[:, :, k] ./ grid_area
            end
            t = ds["time"][:]
            append!(months_all, t)
            C_all = C_all === nothing ? data : cat(C_all, data; dims = 3)
        end
    end
    perm = sortperm(months_all)
    return (; lat, lon, t = months_all[perm], C = C_all[:, :, perm])
end

gfed = read_gfed5(RAW_DIR)
@info "GFED5 grid: $(length(gfed.lon)) lon × $(length(gfed.lat)) lat × $(length(gfed.t)) months"

# Conservative regrid 0.25° → 1° by 4×4 block-mean (fluxes are per unit area,
# so simple averaging is conservative for the area-mean flux):
function block_mean(A::AbstractArray{T, 3}, factor::Int) where T
    nx, ny, nt = size(A)
    @assert nx % factor == 0 && ny % factor == 0 "Grid not divisible by $factor"
    out = zeros(Float64, nx ÷ factor, ny ÷ factor, nt)
    @inbounds for it in 1:nt, j in 1:(ny ÷ factor), i in 1:(nx ÷ factor)
        s = 0.0
        for dj in 0:factor-1, di in 0:factor-1
            s += A[(i-1)*factor + di + 1, (j-1)*factor + dj + 1, it]
        end
        out[i, j, it] = s / (factor * factor)
    end
    return out
end

factor = length(gfed.lon) ÷ length(ct.lon)
@assert factor == length(gfed.lat) ÷ length(ct.lat) "GFED-CT grid ratio mismatch"
@info "Regridding GFED5 by factor $factor"
fire_1deg = block_mean(gfed.C, factor)

# ------------------------------------------------------------------
# 4. Read GOSIF-GPP monthly TIFFs, scale, and regrid 0.05° → 1°
#
# Each GeoTIFF is a global 7200×3600 UInt16 raster of monthly-mean GPP × 100
# (g C m⁻² month⁻¹). Fill values (65535 = water, 65534 = perpetual snow/ice)
# are masked to NaN. GeoTIFFs are stored north-up, so the row axis is reversed
# relative to the south-to-north convention used by CT2022 and GFED5; we flip it.
# ------------------------------------------------------------------

function read_gosif_month(path::String)
    raster = ArchGDAL.readraster(path)
    arr = raster[:, :, 1]                          # cols × rows (UInt16)
    out = Array{Float64}(undef, size(arr))
    for k in eachindex(arr)
        v = arr[k]
        out[k] = v in GOSIF_FILL_VALS ? NaN : Float64(v) * GOSIF_SCALE
    end
    return out                                     # g C m⁻² month⁻¹
end

"""
    block_mean_nan(A, factor)

Conservative aggregation of a flux-density field with NaN holes (ocean, ice).
NaN sub-pixels are treated as **zero** for the purpose of computing the
coarse-cell average. This preserves the total mass when the coarse cell is
later multiplied by the coarse-cell area: a 1° cell that is 10% land + 90%
NaN ocean gets a coarse value of `0.1 × land_mean`, so that
`coarse_value × coarse_area == land_mean × land_area`. A cell with no valid
sub-pixels stays NaN.
"""
function block_mean_nan(A::AbstractMatrix, factor::Int)
    nx, ny = size(A)
    @assert nx % factor == 0 && ny % factor == 0
    out = zeros(Float64, nx ÷ factor, ny ÷ factor)
    @inbounds for j in 1:(ny ÷ factor), i in 1:(nx ÷ factor)
        s = 0.0; n_valid = 0
        for dj in 0:factor-1, di in 0:factor-1
            v = A[(i-1)*factor + di + 1, (j-1)*factor + dj + 1]
            if !isnan(v)
                s += v; n_valid += 1
            end
        end
        # Divide by the TOTAL sub-pixel count (factor²), not the valid count,
        # so coastal/partial-land coarse cells aren't inflated.
        out[i, j] = n_valid == 0 ? NaN : s / (factor * factor)
    end
    return out
end

# Build a 72-month stack of GPP at 1°×1° in g C m⁻² month⁻¹:
n_months = 12 * (YEAR_END - YEAR_START + 1)
gpp_1deg = Array{Float64}(undef, length(ct.lon), length(ct.lat), n_months)

for y in YEAR_START:YEAR_END, m in 1:12
    k = 12 * (y - YEAR_START) + m
    tif = joinpath(gosif_dir, replace(gosif_filename(y, m), ".gz" => ""))
    raw = read_gosif_month(tif)                     # 7200 × 3600 g C/m²/month, north-up

    f_gosif = size(raw, 1) ÷ length(ct.lon)
    @assert f_gosif == size(raw, 2) ÷ length(ct.lat) "GOSIF grid ratio mismatch"

    coarse = block_mean_nan(raw, f_gosif)           # 360 × 180 g C/m²/month
    # GeoTIFF row order is north-to-south; CT/GFED is south-to-north → flip lat:
    coarse = reverse(coarse; dims = 2)
    gpp_1deg[:, :, k] = coarse
end
@info "GOSIF-GPP 1° stack built: $(size(gpp_1deg)) (g C m⁻² month⁻¹)"

# ------------------------------------------------------------------
# 5. Read Hashimoto Rh and Rs, derive monthly Rh, regrid 0.5° → 1°
#
# Hashimoto 2015 (Zenodo 4708444):
#   RH_yr_Hashimoto2015.nc — annual Rh, 1901–2012, gC m⁻² yr⁻¹, 0.5°
#   RS_mon_Hashimoto2015.nc — monthly Rs, 1901–2012, gC m⁻² day⁻¹, 0.5°
# Both files use the `co2` variable on dims (lon, lat, lev=1, time), with
# lon ∈ [0.25, 359.75] (0°–360° convention), lat ∈ [-89.75, 89.75]
# (south-to-north), fill value -999.0.
#
# Monthly Rh is derived by scaling monthly Rs by the per-pixel annual Rh/Rs
# ratio (preserves the published annual Rh; takes seasonality from Rs):
#
#   Rh_mon[lon,lat,y,m] = Rs_mon[lon,lat,y,m] *
#                         (Rh_yr[lon,lat,y] / Rs_yr_from_monthly[lon,lat,y])
#   where Rs_yr = ∑_m Rs_mon[m] * days_in_month(y,m)  (used only inside the
#   dimensionless ratio; Rh_mon comes out in the same units as Rs_mon).
#
# Output units: gC m⁻² day⁻¹ (Hashimoto's native unit — different from
# nee/gpp/er in the same file, which are gC m⁻² month⁻¹). Keeping Rh as a
# daily rate avoids a round-trip day⁻¹ → month⁻¹ → day⁻¹ in the calibration
# pipeline (which would introduce ~2–8% per-month error since ClimaLand's
# loader divides by the constant 365.25/12 rather than real days-in-month).
# Hashimoto ends in 2012; 2013..YEAR_END are filled with the 2002..2012
# monthly climatology (12-month repeating cycle, per-pixel).
# ------------------------------------------------------------------

const HASHIMOTO_FILL = -999.0
const N_HASHIMOTO_LON_HALFSHIFT = 180   # 0..360 → -180..180 via circshift by -180

"""
    hashimoto_year_index(y)

Hashimoto time axis starts in 1901; year y is index `y - 1900` in the annual
file and months 12*(y-1901)+1 .. 12*(y-1900) in the monthly file.
"""
hashimoto_year_index(y) = y - 1900
hashimoto_month_range(y) = (12 * (y - 1901) + 1):(12 * (y - 1900))

"""
    shift_lon_0_360_to_180!(A)

Roll the longitude axis (dim 1) of `A` so that data on the 0..360°E grid
([0.5, ..., 359.5] after a 1° regrid) lines up with the [-179.5, ..., 179.5]
convention used by CT2022 / the inversion grid.
"""
shift_lon_0_360_to_180(A) =
    ndims(A) == 2 ? circshift(A, (-N_HASHIMOTO_LON_HALFSHIFT, 0)) :
                    circshift(A, (-N_HASHIMOTO_LON_HALFSHIFT, 0, 0))

# Read annual Rh for 2002..2012 (gC m⁻² yr⁻¹) on the native 0.5° grid:
function read_hashimoto_annual_rh(path; year_start, year_end)
    n_years = year_end - year_start + 1
    out = Array{Float64}(undef, 720, 360, n_years)
    NCDataset(path) do ds
        for (k, y) in enumerate(year_start:year_end)
            slab = Array{Float64}(ds["co2"].var[:, :, 1, hashimoto_year_index(y)])
            slab[slab .<= HASHIMOTO_FILL + 1] .= NaN
            out[:, :, k] = slab
        end
    end
    return out
end

# Read monthly Rs for 2002..2012 in its native units (gC m⁻² day⁻¹).
# Returns (rs_mon, days_per_month_year) where days_per_month_year[y, m] is
# the real days-in-month for that (year, month), used inside the dimensionless
# Rh/Rs ratio to integrate Rs to an annual total.
function read_hashimoto_monthly_rs(path; year_start, year_end)
    n_years = year_end - year_start + 1
    n_months = 12 * n_years
    out = Array{Float64}(undef, 720, 360, n_months)
    dim = Array{Float64}(undef, n_years, 12)
    NCDataset(path) do ds
        k = 0
        for y in year_start:year_end, m in 1:12
            k += 1
            t_idx = 12 * (y - 1901) + m
            slab = Array{Float64}(ds["co2"].var[:, :, 1, t_idx])
            slab[slab .<= HASHIMOTO_FILL + 1] .= NaN
            out[:, :, k] = slab
            dim[y - year_start + 1, m] = Float64(daysinmonth(Date(y, m, 1)))
        end
    end
    return out, dim
end

@info "Reading Hashimoto annual Rh (2002–$HASHIMOTO_YEAR_END)"
rh_yr_half = read_hashimoto_annual_rh(
    joinpath(hashimoto_dir, HASHIMOTO_RH_FILE);
    year_start = YEAR_START,
    year_end   = HASHIMOTO_YEAR_END,
)
@info "Reading Hashimoto monthly Rs (2002–$HASHIMOTO_YEAR_END)"
rs_mon_half, days_in_month_per_year =
    read_hashimoto_monthly_rs(
        joinpath(hashimoto_dir, HASHIMOTO_RS_FILE);
        year_start = YEAR_START,
        year_end   = HASHIMOTO_YEAR_END,
    )

# Derive monthly Rh on the native 0.5° grid by scaling monthly Rs (gC m⁻²
# day⁻¹) by the per-pixel dimensionless annual Rh/Rs ratio:
#   Rs_yr_total[gC m⁻² yr⁻¹] = ∑_m Rs_mon[m] * days_in_month(m)
#   ratio                    = Rh_yr / Rs_yr_total
#   Rh_mon[m, gC m⁻² day⁻¹]  = Rs_mon[m] * ratio
# Ocean (NaN in either) propagates; very small Rs annual totals are masked to
# avoid divide-by-zero blowup.
function derive_monthly_rh_half(rs_mon, rh_yr, days_in_month)
    n_lon, n_lat, n_months = size(rs_mon)
    n_years = size(rh_yr, 3)
    @assert n_months == 12 * n_years
    @assert size(days_in_month) == (n_years, 12)
    out = similar(rs_mon)
    fill!(out, NaN)
    for y in 1:n_years
        idx = (12 * (y - 1)) + 1 : (12 * y)
        rs_slab = @view rs_mon[:, :, idx]                   # 720 × 360 × 12
        rh_slab = @view rh_yr[:, :, y]                       # 720 × 360
        dim_y = @view days_in_month[y, :]                    # 12
        @inbounds for j in 1:n_lat, i in 1:n_lon
            rh_pix = rh_slab[i, j]
            isnan(rh_pix) && continue
            rs_yr_total = 0.0
            valid = true
            for m in 1:12
                v = rs_slab[i, j, m]
                if isnan(v)
                    valid = false; break
                end
                rs_yr_total += v * dim_y[m]
            end
            (!valid || rs_yr_total < 1.0) && continue        # Rs_yr < 1 gC/m²/yr ⇒ skip
            ratio = rh_pix / rs_yr_total                     # dimensionless
            for m in 1:12
                out[i, j, idx[m]] = rs_slab[i, j, m] * ratio
            end
        end
    end
    return out
end

@info "Deriving monthly Rh = Rs × (annual Rh / annual Rs) on 0.5° grid"
rh_mon_half =
    derive_monthly_rh_half(rs_mon_half, rh_yr_half, days_in_month_per_year)
rh_yr_half = nothing                                         # free memory
rs_mon_half = nothing

# Regrid 0.5° → 1° (factor 2) per time slice, then shift longitude:
@info "Regridding Rh 0.5° → 1° and rolling longitude 0..360 → -180..180"
function regrid_and_shift(rh_half)
    n_months = size(rh_half, 3)
    out = Array{Float64}(undef, 360, 180, n_months)
    for k in 1:n_months
        coarse = block_mean_nan(rh_half[:, :, k], 2)
        out[:, :, k] = shift_lon_0_360_to_180(coarse)
    end
    return out
end
rh_mon_1deg_native = regrid_and_shift(rh_mon_half)            # 2002..2012 only
rh_mon_half = nothing

# Build the full 2002..YEAR_END monthly Rh stack:
# years 2002..HASHIMOTO_YEAR_END use the derived monthly values directly;
# years HASHIMOTO_YEAR_END+1..YEAR_END are filled with the 2002..2012
# monthly climatology (mean by calendar month, per pixel, ignoring NaNs).
function build_full_rh_stack(rh_native, year_start, year_end_native, year_end)
    n_lon, n_lat, _ = size(rh_native)
    n_months_full = 12 * (year_end - year_start + 1)
    out = Array{Float64}(undef, n_lon, n_lat, n_months_full)
    n_native = year_end_native - year_start + 1
    out[:, :, 1:(12 * n_native)] = rh_native
    # Compute climatology: 12 maps, mean over native years per calendar month.
    if year_end > year_end_native
        clim = Array{Float64}(undef, n_lon, n_lat, 12)
        for m in 1:12
            stack = view(rh_native, :, :, m:12:(12 * n_native))
            tmp = Array{Float64}(undef, n_lon, n_lat)
            @inbounds for j in 1:n_lat, i in 1:n_lon
                s = 0.0; c = 0
                for k in 1:size(stack, 3)
                    v = stack[i, j, k]
                    if !isnan(v)
                        s += v; c += 1
                    end
                end
                tmp[i, j] = c == 0 ? NaN : s / c
            end
            clim[:, :, m] = tmp
        end
        for y in (year_end_native + 1):year_end
            base = 12 * (y - year_start)
            for m in 1:12
                out[:, :, base + m] = clim[:, :, m]
            end
        end
    end
    return out
end

rh_1deg = build_full_rh_stack(
    rh_mon_1deg_native, YEAR_START, HASHIMOTO_YEAR_END, YEAR_END,
)
rh_mon_1deg_native = nothing
@info "Hashimoto-derived Rh 1° monthly stack built: $(size(rh_1deg)) (g C m⁻² day⁻¹)"

# ------------------------------------------------------------------
# 6. Compute NEE and ER
# ------------------------------------------------------------------

@assert length(ct.t) == length(gfed.t) == n_months "Time axes inconsistent"
@assert size(ct.nee, 3) == size(fire_1deg, 3) == size(gpp_1deg, 3) "Stacks not aligned"

# CT2022 `bio_flux_opt` is already the inversion's NEE-like estimate
# (fire imposed separately). No fire subtraction required.
nee = ct.nee   # g C m^-2 month^-1, positive = source

# Ecosystem respiration as residual (atmospheric convention, positive = source):
#   NEE_atm = ER − GPP_uptake   ⇒   ER = NEE_atm + GPP_uptake
er = nee .+ gpp_1deg

# ------------------------------------------------------------------
# 7. Write output netCDF
# ------------------------------------------------------------------

outpath = joinpath(OUTPUT_DIR, OUTPUT_FILE)
isfile(outpath) && rm(outpath)

NCDataset(outpath, "c") do ds
    ds.dim["lon"]  = length(ct.lon)
    ds.dim["lat"]  = length(ct.lat)
    ds.dim["time"] = length(ct.t)

    defVar(ds, "lon", Float64.(ct.lon), ("lon",),
           attrib = Dict("units" => "degrees_east", "long_name" => "longitude"))
    defVar(ds, "lat", Float64.(ct.lat), ("lat",),
           attrib = Dict("units" => "degrees_north", "long_name" => "latitude"))

    # Encode time as days since YEAR_START-01-15 (mid-month of first record):
    t_ref = DateTime(YEAR_START, 1, 15)
    t_days = [Float64((Date(year(x), month(x), 15) - Date(t_ref)).value) for x in ct.t]
    defVar(ds, "time", t_days, ("time",),
           attrib = Dict("units" => "days since $(t_ref)", "calendar" => "standard",
                         "long_name" => "mid-month timestamp"))

    common = Dict("units" => "g C m-2 month-1",
                  "_FillValue" => Float32(NaN),
                  "missing_value" => Float32(NaN))

    defVar(ds, "nee", Float32.(nee), ("lon", "lat", "time"),
           attrib = merge(common, Dict(
               "long_name" => "NEE from CarbonTracker CT2022 bio_flux_opt (positive = source)",
               "description" => "CT2022 optimized biospheric flux. Fire already separated (see fire_ct). Residual contamination: LUC and lateral fluxes.",
               "source" => "https://gml.noaa.gov/aftp/products/carbontracker/co2/CT2022/"
           )))
    defVar(ds, "gpp", Float32.(gpp_1deg), ("lon", "lat", "time"),
           attrib = merge(common, Dict(
               "long_name" => "Gross Primary Production, GOSIF-GPP v2 (positive = uptake)",
               "sign_convention" => "positive = carbon flux from atmosphere to ecosystem",
               "source" => "http://data.globalecology.unh.edu/data/GOSIF-GPP_v2/"
           )))
    defVar(ds, "er", Float32.(er), ("lon", "lat", "time"),
           attrib = merge(common, Dict(
               "long_name" => "Ecosystem Respiration, residual: ER = NEE + GPP",
               "sign_convention" => "positive = carbon flux from ecosystem to atmosphere",
               "description" => "Computed as nee + gpp. Inherits LUC/lateral residuals from NEE and retrieval bias from GPP."
           )))
    defVar(ds, "fire_gfed5", Float32.(fire_1deg), ("lon", "lat", "time"),
           attrib = merge(common, Dict(
               "long_name" => "GFED5.1 monthly C emissions, regridded to 1°×1° (diagnostic only)",
               "source" => "https://zenodo.org/records/16794692"
           )))
    defVar(ds, "fire_ct", Float32.(ct.fire_ct), ("lon", "lat", "time"),
           attrib = merge(common, Dict(
               "long_name" => "CT2022 imposed fire flux (GFED4.1s, used internally by the inversion)",
               "description" => "Provided for diagnostic; not used in the NEE/ER derivation."
           )))
    defVar(ds, "rh", Float32.(rh_1deg), ("lon", "lat", "time"),
           attrib = merge(common, Dict(
               "units" => "g C m-2 day-1",
               "long_name" => "Heterotrophic respiration derived from Hashimoto 2015 (positive = source)",
               "description" => "Monthly Rh = Hashimoto monthly Rs (gC m⁻² day⁻¹, native units) × (annual Hashimoto Rh / annual sum of monthly Rs × days_in_month), per pixel. Result is the mean daily rate over each month (gC m⁻² day⁻¹), kept in Hashimoto's native units to avoid a day⁻¹↔month⁻¹ round-trip in calibration. NOTE: different units from nee/gpp/er in this file. Hashimoto covers 1901–$(HASHIMOTO_YEAR_END); $(HASHIMOTO_YEAR_END + 1)–$(YEAR_END) are filled with the 2002–$(HASHIMOTO_YEAR_END) per-pixel monthly climatology. Intended as a soft constraint (magnitude prior on Rh) in calibration, not a pixel-by-pixel target.",
               "source" => "https://zenodo.org/records/4708444 (Hashimoto et al. 2015, Biogeosciences 12: 4121–4132)"
           )))

    ds.attrib["title"] = "Derived NEE, GPP, ER, and Rh on 1°×1° monthly grid ($(YEAR_START)–$(YEAR_END))"
    ds.attrib["sign_convention"] = "NEE, ER, Rh, fire: positive = source. GPP: positive = uptake."
    ds.attrib["created_on"] = string(Dates.now())
    ds.attrib["created_by"] = "ClimaArtifacts/inversion_nee/create_artifact.jl"
    ds.attrib["references"] = "CarbonTracker CT2022 (NOAA/GML); Chen et al. 2023 GFED5 (10.5194/essd-15-5227-2023); Li & Xiao 2019 GOSIF-GPP (10.3390/rs11050517); Hashimoto et al. 2015 (10.5194/bg-12-4121-2015)"
end

@info "Wrote $outpath"

# ------------------------------------------------------------------
# 8. Register the artifact
# ------------------------------------------------------------------

create_artifact_guided(OUTPUT_DIR; artifact_name = basename(@__DIR__))
