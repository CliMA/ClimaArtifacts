# Global water table depth (annual mean) from Fan et al. (2017), PNAS,
# doi:10.1073/pnas.1712381114.
#
# The data is distributed by the Universidade de Santiago de Compostela as five continental
# tiles on a common 30 arc-second (1/120 degree) lattice. This script creates two artifacts:
#
# - `fan2017_water_table_depth_30arcseconds`: the tiles mosaicked onto one global lat-lon
#   grid, without interpolation or averaging;
# - `fan2017_water_table_depth_1degree`: the mean over each 1-degree cell of the depth capped
#   at 15 m, the observations of the ClimaLand water table leaderboard.
#
# Run from this directory with `julia --project create_artifact.jl`.

using Downloads
using NCDatasets
using ClimaArtifactsHelper

# The server does not respond to https
const BASE_URL = "http://thredds-gfnl.usc.es/thredds/fileServer/GLOBALWTDFTP/annualmeans"
const REGIONS = ["AFRICA", "EURASIA", "NAMERICA", "OCEANIA", "SAMERICA"]

const ARTIFACT_NAME_30ARCSEC = basename(@__DIR__) * "_30arcseconds"
const ARTIFACT_NAME_1DEG = basename(@__DIR__) * "_1degree"
const OUTPUT_DIR_30ARCSEC = ARTIFACT_NAME_30ARCSEC * "_artifact"
const OUTPUT_DIR_1DEG = ARTIFACT_NAME_1DEG * "_artifact"
const OUTPUT_FILE_30ARCSEC =
    joinpath(OUTPUT_DIR_30ARCSEC, "fan2017_wtd_annualmean_30arcsec.nc")
const OUTPUT_FILE_1DEG = joinpath(OUTPUT_DIR_1DEG, "fan2017_wtd_1deg.nc")

const CELLS_PER_DEGREE = 120
const NLON = 360 * CELLS_PER_DEGREE
const NLAT = 180 * CELLS_PER_DEGREE

# The source packs WTD into Int16 with scale_factor = 1000/65535 and add_offset ≈ -500, so
# the full Int16 range maps onto [-1000, 0] m (negative below the surface) and no code is
# free for a fill value. We store the depth as a positive number with the same quantization,
# by negating the packed values and the offset. The few cells at -1000 m, whose code
# typemin(Int16) has no negation, are first moved to -999.985 m. This frees typemin(Int16)
# for the fill value. All other values are exactly the negation of the source values.
const FILL_VALUE = typemin(Int16)

# Depth (m) at which the 1-degree product caps the depth before averaging: the depth of the
# soil column in ClimaLand, so that the mean is comparable with the grid-mean water table of
# TOPMODEL. This cap is a ClimaLand choice, not part of Fan et al. (2017)
const CAP_1DEG = 15.0

# Global attributes copied from the source files
const SOURCE_GLOBAL_ATTRIBUTES =
    ["disclaimer", "reference", "project", "acknowledgment", "creator_name", "institution"]

const SOURCE_URLS = join(["$BASE_URL/$(region)_WTD_annualmean.nc" for region in REGIONS], " ")

"""
    lattice_offset(first_center, origin)

Return the 0-based index offset of a tile on the global 30 arc-second lattice that starts at
`origin` (-180 for longitude, -90 for latitude), given the tile's first cell center.

The tiles store coordinates in Float32, which drifts by up to ~0.1 cells along an axis, so
tiles are placed using only their first coordinate.
"""
function lattice_offset(first_center, origin)
    offset = (first_center - origin) * CELLS_PER_DEGREE - 0.5
    abs(offset - round(offset)) < 0.01 || error("Tile is not on the 30 arc-second lattice")
    return round(Int, offset)
end

function make_output_dir(output_dir)
    if isdir(output_dir)
        @warn "$output_dir already exists. Content will end up in the artifact and may be overwritten."
        @warn "Abort this calculation, unless you know what you are doing."
    else
        mkdir(output_dir)
    end
end

function download_tiles()
    for region in REGIONS
        file_name = "$(region)_WTD_annualmean.nc"
        isfile(file_name) && continue
        @info "$file_name not found, downloading it"
        downloaded_file = Downloads.download(
            "$BASE_URL/$file_name";
            progress = download_rate_callback(),
        )
        Base.mv(downloaded_file, file_name)
    end
end

function create_30arcsec_mosaic()
    wtd = fill(FILL_VALUE, NLON, NLAT)
    scale_factor = add_offset = nothing
    source_attributes = Dict{String, Any}()
    num_cells_moved_off_fill = 0

    for region in REGIONS
        @info "Adding $region"
        NCDataset("$(region)_WTD_annualmean.nc") do ds
            # Every tile must share the same packing, otherwise the packed values cannot be
            # combined
            tile_scale_factor = ds["WTD"].attrib["scale_factor"]
            tile_add_offset = ds["WTD"].attrib["add_offset"]
            if isnothing(scale_factor)
                scale_factor, add_offset = tile_scale_factor, tile_add_offset
                for name in SOURCE_GLOBAL_ATTRIBUTES
                    source_attributes[name] = ds.attrib[name]
                end
            end
            (tile_scale_factor, tile_add_offset) == (scale_factor, add_offset) ||
                error("$region uses a different packing")

            i0 = lattice_offset(Float64(ds["lon"][1]), -180)
            j0 = lattice_offset(Float64(ds["lat"][1]), -90)

            # Packed values: dimensions are (lon, lat, time)
            packed = ds["WTD"].var[:, :, 1]
            mask = ds["mask"].var[:, :]
            size(packed) == size(mask) || error("$region: WTD and mask have different sizes")

            for j in axes(packed, 2), i in axes(packed, 1)
                mask[i, j] == 1 || continue
                wtd[i0 + i, j0 + j] == FILL_VALUE ||
                    error("$region overlaps another tile at ($(i0 + i), $(j0 + j))")
                value = packed[i, j]
                if value == FILL_VALUE
                    value += one(Int16)
                    num_cells_moved_off_fill += 1
                end
                wtd[i0 + i, j0 + j] = -value
            end
        end
    end
    @info "Moved $num_cells_moved_off_fill cells from 1000 m to 999.985 m to free the fill value"
    @info "Land cells with data: $(count(!=(FILL_VALUE), wtd))"

    lon = [-180 + (i - 0.5) / CELLS_PER_DEGREE for i in 1:NLON]
    lat = [-90 + (j - 0.5) / CELLS_PER_DEGREE for j in 1:NLAT]

    NCDataset(OUTPUT_FILE_30ARCSEC, "c") do ds
        ds.attrib["title"] = "Global water table depth, annual mean, from Fan et al. (2017)"
        for name in SOURCE_GLOBAL_ATTRIBUTES
            ds.attrib[name] = source_attributes[name]
        end
        ds.attrib["source"] = SOURCE_URLS
        ds.attrib["history"] =
            "Continental tiles mosaicked onto a global grid by " *
            "https://github.com/CliMA/ClimaArtifacts/tree/main/fan2017_water_table_depth. " *
            "The sign is flipped so that the depth is positive below the surface. Values " *
            "are otherwise unchanged, except that the few cells at 1000 m were moved to " *
            "999.985 m to free the Int16 fill value."

        defVar(
            ds,
            "lon",
            lon,
            ("lon",);
            attrib = [
                "units" => "degrees_east",
                "long_name" => "longitude",
                "standard_name" => "longitude",
            ],
        )
        defVar(
            ds,
            "lat",
            lat,
            ("lat",);
            attrib = [
                "units" => "degrees_north",
                "long_name" => "latitude",
                "standard_name" => "latitude",
            ],
        )
        var = defVar(
            ds,
            "wtd",
            Int16,
            ("lon", "lat");
            fillvalue = FILL_VALUE,
            deflatelevel = 4,
            shuffle = true,
            chunksizes = (1440, 720),
            attrib = [
                "long_name" => "water table depth, annual mean",
                "units" => "m",
                "scale_factor" => Float64(scale_factor),
                "add_offset" => -Float64(add_offset),
                "comment" =>
                    "Depth of the water table below the land surface, positive downward: " *
                    "0 means the water table is at the surface. The source files store " *
                    "the negative of this. The packing limits values to [0, 1000] m. " *
                    "Missing over oceans and regions outside the five model domains " *
                    "(e.g., Antarctica, Greenland, Iceland).",
            ],
        )
        # Write the packed values directly, bypassing scale_factor/add_offset
        var.var[:, :] = wtd
    end
    return nothing
end

"""
    block_range(block)

Return the indices of the 30 arc-second cells whose centers fall in the 1-degree cell
`block`, centered on a whole degree and covering [center - 0.5, center + 0.5). Indices can be
outside of the grid at its edges.
"""
block_range(block) =
    ((block - 1) * CELLS_PER_DEGREE - CELLS_PER_DEGREE ÷ 2 + 1):((block - 1) * CELLS_PER_DEGREE + CELLS_PER_DEGREE ÷ 2)

"""
    mean_capped_depth(packed, scale_factor, add_offset)

Return the mean over each 1-degree cell of the depth capped at `CAP_1DEG`, given the packed
30 arc-second depths. Cells without land data are NaN.

Cells are centered on whole degrees: longitudes -180, ..., 179 and latitudes -90, ..., 89.
The cell at -180 wraps around the dateline, the cell at -90 is half a cell, and the 30
arc-second cells north of 89.5 (no land in the data) are not used.
"""
function mean_capped_depth(packed::Matrix{Int16}, scale_factor::Float64, add_offset::Float64)
    wtd_mean15 = fill(NaN32, 360, 180)
    for jb in axes(wtd_mean15, 2), ib in axes(wtd_mean15, 1)
        total = 0.0
        num_cells = 0
        for j in block_range(jb)
            1 <= j <= NLAT || continue
            for i in block_range(ib)
                value = packed[mod1(i, NLON), j]
                value == FILL_VALUE && continue
                total += min(value * scale_factor + add_offset, CAP_1DEG)
                num_cells += 1
            end
        end
        num_cells > 0 && (wtd_mean15[ib, jb] = total / num_cells)
    end
    return wtd_mean15
end

function create_1deg_mean()
    NCDataset(OUTPUT_FILE_30ARCSEC) do ds_in
        var = ds_in["wtd"]
        wtd_mean15 = mean_capped_depth(
            var.var[:, :],
            Float64(var.attrib["scale_factor"]),
            Float64(var.attrib["add_offset"]),
        )
        @info "1-degree cells with data: $(count(isfinite, wtd_mean15))"
        lon = collect(-180.0:179.0)
        lat = collect(-90.0:89.0)

        NCDataset(OUTPUT_FILE_1DEG, "c") do ds
            ds.attrib["title"] =
                "Global water table depth, annual mean, from Fan et al. (2017), " *
                "capped at $(CAP_1DEG) m and averaged on a 1-degree grid"
            for name in SOURCE_GLOBAL_ATTRIBUTES
                ds.attrib[name] = ds_in.attrib[name]
            end
            ds.attrib["source"] = SOURCE_URLS
            ds.attrib["history"] =
                "Aggregated from $(basename(OUTPUT_FILE_30ARCSEC)) by " *
                "https://github.com/CliMA/ClimaArtifacts/tree/main/fan2017_water_table_depth"

            defVar(
                ds,
                "lon",
                lon,
                ("lon",);
                attrib = ["units" => "degrees_east", "standard_name" => "longitude"],
            )
            defVar(
                ds,
                "lat",
                lat,
                ("lat",);
                attrib = ["units" => "degrees_north", "standard_name" => "latitude"],
            )
            # NaN, not a fill value, marks cells without land: the ClimaLand leaderboard
            # masks with isfinite
            defVar(
                ds,
                "wtd_mean15",
                wtd_mean15,
                ("lon", "lat");
                deflatelevel = 4,
                attrib = [
                    "units" => "m",
                    "long_name" => "Water table depth",
                    "description" =>
                        "Mean over the 1 degree cell (centred on whole degrees) of " *
                        "min(WTD, $(CAP_1DEG) m), WTD the annual-mean depth at 30 " *
                        "arc-seconds, positive below the surface. NaN without land data.",
                ],
            )
        end
    end
    return nothing
end

make_output_dir(OUTPUT_DIR_30ARCSEC)
make_output_dir(OUTPUT_DIR_1DEG)

download_tiles()

# Both steps take a few minutes, so their outputs are reused if present. Delete them to
# regenerate them
if isfile(OUTPUT_FILE_30ARCSEC)
    @info "$OUTPUT_FILE_30ARCSEC already exists, skipping the mosaic"
else
    create_30arcsec_mosaic()
end
if isfile(OUTPUT_FILE_1DEG)
    @info "$OUTPUT_FILE_1DEG already exists, skipping the 1-degree mean"
else
    create_1deg_mean()
end

create_artifact_guided(OUTPUT_DIR_30ARCSEC; artifact_name = ARTIFACT_NAME_30ARCSEC)
create_artifact_guided(OUTPUT_DIR_1DEG; artifact_name = ARTIFACT_NAME_1DEG, append = true)
