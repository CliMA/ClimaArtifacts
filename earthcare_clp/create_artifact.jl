#=
Gridded monthly cloud fraction on levels and liquid and frozen water paths
from EarthCARE ACM_CLP (JAXA cloud retrieval from CPR, ATLID, and MSI).

A granule is one product file: one orbit frame of about 5000 km of ground
track, a few thousand profiles with 206 height bins of 100 m from 20 km
down to -500 m. Every valid bin of every granule is counted into a
2.5 deg by 2.5 deg by 500 m grid, and every profile's water paths are
summed into the 2.5 deg by 2.5 deg column grid. One NetCDF per month,
stitched along time into earthcare_clp_2.5x2.5.nc. Summing blocks of 4 by 4
cells gives the 10 deg by 10 deg earthcare_clp_10x10.nc, a separate
artifact named earthcare_clp_lowres.

Variable names and units follow the calipso_cloudsat artifact so the same
data loader reads both. Directories and baseline are in earthcare_settings.jl.
=#
using HDF5
using NCDatasets
using Dates
using ClimaArtifactsHelper

include("earthcare_settings.jl")

const ARTIFACT_NAME = basename(@__DIR__)

const LON_EDGES = -180.0:2.5:180.0
const LAT_EDGES = -90.0:2.5:90.0
const Z_EDGES = 0.0:500.0:20_000.0

# 2.5 deg cells per 10 deg cell along lon and along lat.
const LOWRES_FACTOR = 4

# Water content and path variable names, newest baseline first. JXBB renamed them.
const LWP_NAMES = ("liquid_water_path_1km", "cloud_water_path_1km")
const FWP_NAMES = ("ice_water_path_1km", "cloud_ice_water_path_1km")
const GEO_GROUP = "ScienceData/Geo"
const DATA_GROUP = "ScienceData/Data"

# Layout of a JXBB granule, checked on ECA_JXBB_ACM_CLP_2B_20241126T184343Z:
# cloud_mask_cpr_atlid_msi_1km is 1 cloud, 0 clear, -9 not observed (below
# the surface or in surface clutter), -127 fill. Water paths are per
# profile, negative where there is no cloud, and above 1e30 where fill.
const MASK_CLOUD = Int8(1)
const MASK_CLEAR = Int8(0)
const FILL_FLOAT = 1e30

# Filenames look like ECA_JXBB_ACM_CLP_2B_20260101T000000Z_20260101T001200Z_03456D.h5
baseline(path) = String(split(basename(path), "_")[2])
month_key(path) = split(basename(path), "_")[6][1:6]
start_time(path) = DateTime(split(basename(path), "_")[6][1:15], dateformat"yyyymmddTHHMMSS")

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

struct Grid
    total_counts::Array{Int32, 3}   # lon, lat, z
    cloud_counts::Array{Int32, 3}
    sum_lwp::Array{Float64, 2}      # lon, lat
    sum_fwp::Array{Float64, 2}
    profile_counts::Array{Int32, 2}
end

function Grid()
    nlon, nlat, nz = nbins(LON_EDGES), nbins(LAT_EDGES), nbins(Z_EDGES)
    return Grid(
        zeros(Int32, nlon, nlat, nz), zeros(Int32, nlon, nlat, nz),
        zeros(Float64, nlon, nlat), zeros(Float64, nlon, nlat), zeros(Int32, nlon, nlat),
    )
end

function first_present(group, names, path)
    for name in names
        haskey(group, name) && return name
    end
    error("None of $names found in $path")
end

# Factor that takes a variable with the given units attribute to kg m^-2.
function to_kg_per_m2(dataset, path)
    units = haskey(attrs(dataset), "units") ? attrs(dataset)["units"] : ""
    startswith(units, "g") && return 1e-3
    startswith(units, "kg") && return 1.0
    error("Unknown water path units \"$units\" in $path")
end

"""
    read_granule(path)

Fields of one granule. HDF5.jl returns the C-ordered (ray, bin) arrays as
(bin, ray), so 2D fields are indexed `x[k, i]` with `k` the range bin.
"""
function read_granule(path)
    h5open(path, "r") do hf
        geo, data = hf[GEO_GROUP], hf[DATA_GROUP]
        lwp_name = first_present(data, LWP_NAMES, path)
        fwp_name = first_present(data, FWP_NAMES, path)
        return (
            lat = read(geo["latitude"]),
            lon = read(geo["longitude"]),
            z = read(geo["height"]),
            cmask = read(data["cloud_mask_cpr_atlid_msi_1km"]),
            lwp = read(data[lwp_name]) .* to_kg_per_m2(data[lwp_name], path),
            fwp = read(data[fwp_name]) .* to_kg_per_m2(data[fwp_name], path),
        )
    end
end

# height is 1D (bin) or 2D (bin, ray) depending on the baseline.
height_at(z::AbstractVector, k, i) = z[k]
height_at(z::AbstractMatrix, k, i) = z[k, i]

function accumulate!(G::Grid, g)
    nbin, nray = size(g.cmask)
    for i in 1:nray
        ilon = bin_index(g.lon[i], LON_EDGES)
        ilat = bin_index(g.lat[i], LAT_EDGES)
        (ilon == 0 || ilat == 0) && continue
        for k in 1:nbin
            iz = bin_index(height_at(g.z, k, i), Z_EDGES)
            iz == 0 && continue
            cmask = g.cmask[k, i]
            (cmask == MASK_CLOUD || cmask == MASK_CLEAR) || continue
            G.total_counts[ilon, ilat, iz] += 1
            G.cloud_counts[ilon, ilat, iz] += cmask == MASK_CLOUD
        end
        lwp, fwp = g.lwp[i], g.fwp[i]
        (lwp > FILL_FLOAT || fwp > FILL_FLOAT) && continue
        G.sum_lwp[ilon, ilat] += max(lwp, 0.0)
        G.sum_fwp[ilon, ilat] += max(fwp, 0.0)
        G.profile_counts[ilon, ilat] += 1
    end
    return nothing
end

"""
    block_sum(x, n)

Sum each block of `n` by `n` cells over the first two dimensions of `x`.
"""
function block_sum(x, n)
    size(x, 1) % n == 0 && size(x, 2) % n == 0 || error("Grid $(size(x)) does not divide into blocks of $n")
    y = zeros(eltype(x), size(x, 1) ÷ n, size(x, 2) ÷ n, size(x)[3:end]...)
    for I in CartesianIndices(x)
        i, j, rest... = Tuple(I)
        y[cld(i, n), cld(j, n), rest...] += x[I]
    end
    return y
end

coarsen(G::Grid, n) = Grid(
    block_sum(G.total_counts, n), block_sum(G.cloud_counts, n),
    block_sum(G.sum_lwp, n), block_sum(G.sum_fwp, n), block_sum(G.profile_counts, n),
)

"""
    read_month(path)

Grid and global attributes of a file written by `write_month`. Water path
sums are the means times the profile counts.
"""
function read_month(path)
    NCDataset(path) do ds
        np = Array{Int32}(ds["profile_counts"][:, :, 1])
        path_sum(name) = ifelse.(np .> 0, ds[name][:, :, 1] .* np, 0.0)
        G = Grid(
            ds["total_counts_on_levels"][:, :, :, 1], ds["cloud_counts_on_levels"][:, :, :, 1],
            path_sum("lwp"), path_sum("fwp"), np,
        )
        return G, Dict(k => v for (k, v) in ds.attrib)
    end
end

"""
    write_month(path, G, date, attribs)

Divide the counts and sums into fractions and means and write one NetCDF
file with a time dimension of length one. The lon and lat cells evenly
divide the globe, as many as `G` has.
"""
function write_month(path, G::Grid, date::DateTime, attribs)
    nlon, nlat = size(G.profile_counts)
    lon_edges = range(first(LON_EDGES), last(LON_EDGES), length = nlon + 1)
    lat_edges = range(first(LAT_EDGES), last(LAT_EDGES), length = nlat + 1)
    ds = NCDataset(path, "c", attrib = attribs)
    defDim(ds, "lon", nlon)
    defDim(ds, "lat", nlat)
    defDim(ds, "height", nbins(Z_EDGES))
    defDim(ds, "time", 1)
    defVar(ds, "lon", midpoints(lon_edges), ("lon",), attrib = Dict("units" => "degrees_east"))
    defVar(ds, "lat", midpoints(lat_edges), ("lat",), attrib = Dict("units" => "degrees_north"))
    defVar(ds, "height", midpoints(Z_EDGES), ("height",), attrib = Dict("units" => "m", "long_name" => "height above mean sea level"))
    defVar(ds, "time", [date], ("time",), attrib = Dict("units" => "seconds since 2024-11-01 00:00:00"))
    defVar(ds, "baseline", [attribs["baseline"]], ("time",), attrib = Dict("long_name" => "processing baseline"))

    put(name, x, dims, units, long_name) = defVar(
        ds, name, reshape(x, size(x)..., 1), dims,
        attrib = Dict("units" => units, "long_name" => long_name),
    )
    dims3 = ("lon", "lat", "height", "time")
    dims2 = ("lon", "lat", "time")
    n = Float64.(G.total_counts)
    put("cloud_fraction_on_levels", ifelse.(n .> 0, 100 .* G.cloud_counts ./ n, NaN), dims3, "%", "cloudy bins over valid bins, times 100")
    put("cloud_counts_on_levels", G.cloud_counts, dims3, "1", "cloudy range bins")
    put("total_counts_on_levels", G.total_counts, dims3, "1", "valid range bins")
    np = Float64.(G.profile_counts)
    put("lwp", ifelse.(np .> 0, G.sum_lwp ./ np, NaN), dims2, "kg m^-2", "liquid water path, cloud liquid plus rain, mean over all profiles")
    put("fwp", ifelse.(np .> 0, G.sum_fwp ./ np, NaN), dims2, "kg m^-2", "frozen water path, cloud ice plus snow, mean over all profiles")
    put("profile_counts", G.profile_counts, dims2, "1", "valid profiles")
    close(ds)
    return path
end

"""
    stitch(files, output_filepath)

Concatenate the monthly files along time into one NetCDF file. The
per-month `n_granule` attribute becomes a variable along time.
"""
function stitch(files, output_filepath)
    @info "Creating $output_filepath"
    n_granule = [NCDataset(f -> Int32(f.attrib["n_granule"]), file) for file in files]
    mfds = NCDataset(files, aggdim = "time")
    attribs = Dict(k => v for (k, v) in mfds.attrib if !(v isa AbstractVector) && k != "n_granule")
    attribs["history"] = "Created by CliMA (see earthcare_clp folder in ClimaArtifacts)"
    ds = NCDataset(output_filepath, "c", attrib = attribs)
    for d in dimnames(mfds)
        ds.dim[d] = mfds.dim[d]
    end
    for (name, _) in mfds
        defVar(ds, name, Array(mfds[name]), dimnames(mfds[name]), attrib = mfds[name].attrib)
    end
    defVar(ds, "n_granule", n_granule, ("time",), attrib = Dict("units" => "1", "long_name" => "granules in the month"))
    close(ds)
    close(mfds)
    return output_filepath
end

files = filter(f -> endswith(f, ".h5"), readdir(GRANULE_DIR, join = true))
isempty(files) && error("No .h5 granules found in $GRANULE_DIR")
n_all = length(files)
filter!(f -> START_DATE <= start_time(f) < END_DATE, files)
@info "Using $(length(files)) of $n_all granules from $START_DATE to $END_DATE"
isempty(files) && error("No granules from $START_DATE to $END_DATE in $GRANULE_DIR")
if !isempty(BASELINE)
    n_all = length(files)
    filter!(f -> baseline(f) == BASELINE, files)
    @info "Using $(length(files)) of $n_all granules with baseline $BASELINE"
    isempty(files) && error("No $BASELINE granules in $GRANULE_DIR")
end

monthly_dir = joinpath(OUTPUT_DIR, "monthly")
mkpath(monthly_dir)
monthly_files = String[]
monthly_files_lowres = String[]
for key in sort(unique(month_key.(files)))
    date = DateTime(parse(Int, key[1:4]), parse(Int, key[5:6]))
    out = joinpath(monthly_dir, "earthcare_clp_2.5x2.5_$key.nc")
    if isfile(out)
        @info "Skipping month $key (already exists)"
    else
        group = filter(f -> month_key(f) == key, files)
        bl = unique(baseline.(group))
        length(bl) == 1 || error("Mixed baselines $bl in month $key; set BASELINE")
        G = Grid()
        for f in group
            @info "Accumulating $(basename(f))"
            accumulate!(G, read_granule(f))
        end
        attribs = Dict(
            "baseline" => only(bl),
            "n_granule" => length(group),
            "valid_rule" => "cloud_mask in (0, 1); -9 not observed and -127 fill excluded",
            "path_rule" => "negative water path means no cloud and counts as zero",
        )
        write_month(out, G, date, attribs)
    end
    push!(monthly_files, out)

    out_lowres = joinpath(monthly_dir, "earthcare_clp_10x10_$key.nc")
    if !isfile(out_lowres)
        G, attribs = read_month(out)
        write_month(out_lowres, coarsen(G, LOWRES_FACTOR), date, attribs)
    end
    push!(monthly_files_lowres, out_lowres)
end

artifact_dir = joinpath(OUTPUT_DIR, ARTIFACT_NAME * "_artifact")
artifact_dir_lowres = joinpath(OUTPUT_DIR, ARTIFACT_NAME * "_lowres_artifact")
mkpath(artifact_dir)
mkpath(artifact_dir_lowres)
stitch(monthly_files, joinpath(artifact_dir, "earthcare_clp_2.5x2.5.nc"))
stitch(monthly_files_lowres, joinpath(artifact_dir_lowres, "earthcare_clp_10x10.nc"))
create_artifact_guided(artifact_dir; artifact_name = ARTIFACT_NAME)
create_artifact_guided(artifact_dir_lowres; artifact_name = ARTIFACT_NAME * "_lowres", append = true)
