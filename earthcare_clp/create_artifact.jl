#=
Gridded monthly statistics from EarthCARE ACM_CLP (JAXA cloud retrieval
from CPR, ATLID, and MSI).

A granule is one product file: one orbit frame of about 5000 km of ground
track, a few thousand profiles with 200 height bins each. Every range bin of
every granule is added into two sets of running sums:

Grid A: lon 2.5 deg, lat 2.5 deg, z 500 m, pass (ascending, descending).
Grid B: lat band 10 deg, temperature bin 2 K from -38 to 0 C, pass. Ocean only.

Sums are divided into means on write, one NetCDF per month, then stitched
along time into earthcare_clp_2.5x2.5.nc.

Settings are the environment variables listed below.
=#
using HDF5
using NCDatasets
using Dates
using ClimaArtifactsHelper

# Settings, all environment variables.
#
# | Variable              | Default                 | Meaning                              |
# |-----------------------|-------------------------|--------------------------------------|
# | EARTHCARE_CLP_DIR     | <this folder>/granules  | directory holding the .h5 granules   |
# | EARTHCARE_OUTPUT_DIR  | <this folder>           | where monthly/ and the artifact go   |
const GRANULE_DIR = get(ENV, "EARTHCARE_CLP_DIR", joinpath(@__DIR__, "granules"))
const OUTPUT_DIR = get(ENV, "EARTHCARE_OUTPUT_DIR", @__DIR__)

const ARTIFACT_NAME = basename(@__DIR__)

const LON_EDGES = -180.0:2.5:180.0
const LAT_EDGES = -90.0:2.5:90.0
const Z_EDGES = 0.0:500.0:20_000.0
const LATB_EDGES = -90.0:10.0:90.0
const T_EDGES = 235.15:2.0:273.15
const NPASS = 2

# Water content variable names per processing baseline (JXBB renamed them).
const VAR_MAP = Dict(
    "JXBA" => (liquid = "cloud_water_content_1km", ice = "cloud_ice_content_1km"),
    "JXBB" => (liquid = "liquid_water_content_1km", ice = "ice_water_content_1km"),
)
const GEO_GROUP = "ScienceData/Geo"
const DATA_GROUP = "ScienceData/Data"

# Fill values in ACM_CLP are large negative numbers.
const FILL = -9000.0
# TODO: confirm both flag values against the vBb release note flag tables.
const CLUTTER = Int8(-1)   # cloud_mask_cpr_atlid_msi_1km value for surface clutter
const OCEAN = Int8(0)      # land_water_flag value for ocean
# Minimum grid-mean condensate (kg m^-3) for SLF to be defined.
const SLF_FLOOR = 1e-7

# Filenames look like ECA_JXBB_ACM_CLP_2B_20260101T000000Z_20260101T001200Z_03456D.h5
baseline(path) = split(basename(path), "_")[2]
month_key(path) = split(basename(path), "_")[6][1:6]

"""
    bin_index(x, edges)

1-based bin of `x` in `edges`, 0 when `x` is outside or not finite.
"""
function bin_index(x, edges)
    (isfinite(x) && first(edges) <= x < last(edges)) || return 0
    return searchsortedlast(edges, x)
end

nbins(edges) = length(edges) - 1
midpoints(edges) = collect((edges[1:(end - 1)] .+ edges[2:end]) ./ 2)

# Ascending pass is near 02:00 local, descending near 14:00 local.
pass_index(lon, t::DateTime) = mod(hour(t) + lon / 15, 24) < 8 ? 1 : 2

# Product time is seconds since 2000-01-01.
to_datetime(t) = DateTime(2000, 1, 1) + Second(round(Int, t))

struct GridA
    n_total::Array{Int32, 4}
    n_cloud::Array{Int32, 4}
    n_clutter::Array{Int32, 4}
    sum_clw::Array{Float64, 4}
    sum_cli::Array{Float64, 4}
    sum_clw2::Array{Float64, 4}
    sum_cli2::Array{Float64, 4}
    sum_ta::Array{Float64, 4}
    n_overpass::Array{Int32, 3}
end

function GridA()
    sz = (nbins(LON_EDGES), nbins(LAT_EDGES), nbins(Z_EDGES), NPASS)
    return GridA(
        zeros(Int32, sz), zeros(Int32, sz), zeros(Int32, sz),
        zeros(Float64, sz), zeros(Float64, sz), zeros(Float64, sz),
        zeros(Float64, sz), zeros(Float64, sz),
        zeros(Int32, nbins(LON_EDGES), nbins(LAT_EDGES), NPASS),
    )
end

struct GridB
    n_total::Array{Int32, 3}
    n_cloud::Array{Int32, 3}
    sum_clw::Array{Float64, 3}
    sum_cli::Array{Float64, 3}
end

function GridB()
    sz = (nbins(LATB_EDGES), nbins(T_EDGES), NPASS)
    return GridB(zeros(Int32, sz), zeros(Int32, sz), zeros(Float64, sz), zeros(Float64, sz))
end

"""
    read_granule(path)

Fields of one granule. HDF5.jl returns the C-ordered (ray, bin) arrays as
(bin, ray), so 2D fields are indexed `x[k, i]` with `k` the range bin.
"""
function read_granule(path)
    names = VAR_MAP[baseline(path)]
    h5open(path, "r") do hf
        geo, data = hf[GEO_GROUP], hf[DATA_GROUP]
        return (
            lat = read(geo["latitude"]),
            lon = read(geo["longitude"]),
            time = to_datetime.(read(geo["time"])),
            z = read(geo["height"]),
            clw = read(data[names.liquid]),
            cli = read(data[names.ice]),
            ta = read(data["GRID_temperature_1km"]),
            cmask = read(data["cloud_mask_cpr_atlid_msi_1km"]),
            land = read(data["land_water_flag"]),
        )
    end
end

# height is 1D (bin) or 2D (bin, ray) depending on the baseline.
height_at(z::AbstractVector, k, i) = z[k]
height_at(z::AbstractMatrix, k, i) = z[k, i]

function accumulate!(A::GridA, B::GridB, g)
    nbin, nray = size(g.clw)
    touched = falses(nbins(LON_EDGES), nbins(LAT_EDGES), NPASS)
    for i in 1:nray
        ilon = bin_index(g.lon[i], LON_EDGES)
        ilat = bin_index(g.lat[i], LAT_EDGES)
        ilatb = bin_index(g.lat[i], LATB_EDGES)
        (ilon == 0 || ilat == 0) && continue
        ip = pass_index(g.lon[i], g.time[i])
        touched[ilon, ilat, ip] = true
        ocean = g.land[i] == OCEAN
        for k in 1:nbin
            clw, cli, ta = g.clw[k, i], g.cli[k, i], g.ta[k, i]
            (clw <= FILL || cli <= FILL || ta <= FILL) && continue
            iz = bin_index(height_at(g.z, k, i), Z_EDGES)
            iz == 0 && continue
            cmask = g.cmask[k, i]
            if cmask == CLUTTER
                A.n_clutter[ilon, ilat, iz, ip] += 1
                continue
            end
            cloudy = cmask == 1
            A.n_total[ilon, ilat, iz, ip] += 1
            A.n_cloud[ilon, ilat, iz, ip] += cloudy
            A.sum_clw[ilon, ilat, iz, ip] += clw
            A.sum_cli[ilon, ilat, iz, ip] += cli
            A.sum_clw2[ilon, ilat, iz, ip] += clw^2
            A.sum_cli2[ilon, ilat, iz, ip] += cli^2
            A.sum_ta[ilon, ilat, iz, ip] += ta
            it = bin_index(ta, T_EDGES)
            (it == 0 || !ocean) && continue
            B.n_total[ilatb, it, ip] += 1
            B.n_cloud[ilatb, it, ip] += cloudy
            B.sum_clw[ilatb, it, ip] += clw
            B.sum_cli[ilatb, it, ip] += cli
        end
    end
    A.n_overpass .+= touched
    return nothing
end

"""
    write_month(path, A, B, date, attribs)

Divide the sums into means and write one NetCDF file with a time dimension
of length one.
"""
function write_month(path, A::GridA, B::GridB, date::DateTime, attribs)
    ds = NCDataset(path, "c", attrib = attribs)
    defDim(ds, "lon", nbins(LON_EDGES))
    defDim(ds, "lat", nbins(LAT_EDGES))
    defDim(ds, "z", nbins(Z_EDGES))
    defDim(ds, "lat_band", nbins(LATB_EDGES))
    defDim(ds, "tbin", nbins(T_EDGES))
    defDim(ds, "pass", NPASS)
    defDim(ds, "time", 1)

    defVar(ds, "lon", midpoints(LON_EDGES), ("lon",), attrib = Dict("units" => "degrees_east"))
    defVar(ds, "lat", midpoints(LAT_EDGES), ("lat",), attrib = Dict("units" => "degrees_north"))
    defVar(ds, "z", midpoints(Z_EDGES), ("z",), attrib = Dict("units" => "m", "long_name" => "height above mean sea level"))
    defVar(ds, "lat_band", midpoints(LATB_EDGES), ("lat_band",), attrib = Dict("units" => "degrees_north"))
    defVar(ds, "tbin", midpoints(T_EDGES), ("tbin",), attrib = Dict("units" => "K"))
    defVar(ds, "pass", Int32[1, 2], ("pass",), attrib = Dict("flag_values" => Int32[1, 2], "flag_meanings" => "ascending descending"))
    defVar(ds, "time", [date], ("time",), attrib = Dict("units" => "seconds since 2025-12-01 00:00:00"))

    put(name, x, dims, units, long_name) = defVar(
        ds, name, reshape(x, size(x)..., 1), dims,
        attrib = Dict("units" => units, "long_name" => long_name),
    )

    dimsA = ("lon", "lat", "z", "pass", "time")
    n = Float64.(A.n_total)
    mean_over_n(x) = ifelse.(n .> 0, x ./ n, NaN)
    tot = A.sum_clw .+ A.sum_cli
    clw = mean_over_n(A.sum_clw)
    cli = mean_over_n(A.sum_cli)
    put("cloud_fraction_on_levels", mean_over_n(A.n_cloud), dimsA, "", "cloudy bins over valid bins")
    put("cloud_liquid_water_content", clw, dimsA, "kg m^-3", "grid-mean cloud liquid water content")
    put("cloud_ice_water_content", cli, dimsA, "kg m^-3", "grid-mean cloud ice water content")
    put("supercooled_liquid_fraction", ifelse.(tot .> SLF_FLOOR .* n, A.sum_clw ./ tot, NaN), dimsA, "", "sum of liquid over sum of liquid plus ice")
    put("temperature", mean_over_n(A.sum_ta), dimsA, "K", "grid-mean auxiliary temperature")
    put("cloud_liquid_variance", mean_over_n(A.sum_clw2) .- clw .^ 2, dimsA, "kg^2 m^-6", "variance of cloud liquid water content within the box")
    put("cloud_ice_variance", mean_over_n(A.sum_cli2) .- cli .^ 2, dimsA, "kg^2 m^-6", "variance of cloud ice water content within the box")
    put("n_total", A.n_total, dimsA, "1", "valid range bins")
    put("n_cloud", A.n_cloud, dimsA, "1", "cloudy range bins")
    put("n_clutter", A.n_clutter, dimsA, "1", "range bins removed as surface clutter")
    put("n_overpass", A.n_overpass, ("lon", "lat", "pass", "time"), "1", "granules contributing to the box")

    dimsB = ("lat_band", "tbin", "pass", "time")
    totB = B.sum_clw .+ B.sum_cli
    put("slf_by_temperature", ifelse.(totB .> 0, B.sum_clw ./ totB, NaN), dimsB, "", "ocean SLF per temperature bin")
    put("cloud_fraction_by_temperature", ifelse.(B.n_total .> 0, B.n_cloud ./ B.n_total, NaN), dimsB, "", "ocean cloud fraction per temperature bin")
    put("n_total_by_temperature", B.n_total, dimsB, "1", "valid ocean range bins per temperature bin")
    put("n_cloud_by_temperature", B.n_cloud, dimsB, "1", "cloudy ocean range bins per temperature bin")
    close(ds)
    return path
end

"""
    stitch(files, output_filepath)

Concatenate the monthly files along time into one NetCDF file.
"""
function stitch(files, output_filepath)
    @info "Creating $output_filepath"
    mfds = NCDataset(files, aggdim = "time")
    attribs = Dict(mfds.attrib)
    attribs["history"] = "Created by CliMA (see earthcare_clp folder in ClimaArtifacts)"
    ds = NCDataset(output_filepath, "c", attrib = attribs)
    for d in dimnames(mfds)
        ds.dim[d] = mfds.dim[d]
    end
    for (name, _) in mfds
        defVar(ds, name, Array(mfds[name]), dimnames(mfds[name]), attrib = mfds[name].attrib)
    end
    close(ds)
    close(mfds)
    return output_filepath
end

files = filter(f -> endswith(f, ".h5"), readdir(GRANULE_DIR, join = true))
isempty(files) && error("No .h5 granules found in $GRANULE_DIR")

monthly_dir = joinpath(OUTPUT_DIR, "monthly")
mkpath(monthly_dir)
monthly_files = String[]
for key in sort(unique(month_key.(files)))
    out = joinpath(monthly_dir, "earthcare_clp_2.5x2.5_$key.nc")
    if isfile(out)
        @info "Skipping month $key (already exists)"
        push!(monthly_files, out)
        continue
    end
    group = filter(f -> month_key(f) == key, files)
    bl = unique(baseline.(group))
    length(bl) == 1 || error("Mixed baselines $bl in month $key")
    A, B = GridA(), GridB()
    for f in group
        @info "Accumulating $(basename(f))"
        accumulate!(A, B, read_granule(f))
    end
    date = DateTime(parse(Int, key[1:4]), parse(Int, key[5:6]))
    attribs = Dict(
        "baseline" => only(bl),
        "liquid_variable" => VAR_MAP[only(bl)].liquid,
        "ice_variable" => VAR_MAP[only(bl)].ice,
        "clutter_rule" => "cloud_mask == $CLUTTER excluded from n_total",
        "fill_rule" => "values <= $FILL excluded from n_total",
        "pass_rule" => "ascending if local hour < 8",
    )
    push!(monthly_files, write_month(out, A, B, date, attribs))
end

artifact_dir = joinpath(OUTPUT_DIR, ARTIFACT_NAME * "_artifact")
mkpath(artifact_dir)
stitch(monthly_files, joinpath(artifact_dir, "earthcare_clp_2.5x2.5.nc"))
create_artifact_guided(artifact_dir; artifact_name = ARTIFACT_NAME)
