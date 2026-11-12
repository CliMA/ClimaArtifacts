# Global LAI derived from MODIS Collection 6.1 data by
# Lin, W., Yuan, H., Dong, W., Zhang, S., Liu, S., Wei, N., Lu, X., Wei, Z.,
# Hu, Y. and Dai, Y., 2023. Reprocessed MODIS Version 6.1 Leaf Area Index
# Dataset and Its Evaluation for Land Surface and Climate Modeling. Remote
# Sensing, 15(7), 1780. https://doi.org/10.3390/rs15071780
# (method: Yuan, H., Dai, Y., Xiao, Z., Ji, D. and Shangguan, W., 2011,
# Remote Sensing of Environment, 115(5), 1171-1187).

# We download the monthly 0.05° files from the data provider and aggregate them
# to the 0.25° grid consumed by the Land model, over the land part of each cell
# only, exactly as for the `modis_lai_0.25deg` artifact (see
# land_fraction_correction.jl and the README).

################################################################################
# IMPORTS                                                                      #
################################################################################

using Artifacts
using NCDatasets
using Dates
using Downloads
using SHA

using ClimaArtifactsHelper

include("land_fraction_correction.jl")

################################################################################
# CONSTANTS                                                                    #
################################################################################

# Source dataset: monthly LAI at 0.05° (20 pixels per degree), one file per year
source_url(year) = "http://globalchange.bnu.edu.cn/laiv061/global_lai_0.05/lai_monthly_0.05_$(year).nc"
source_file(year) = "lai_monthly_0.05_$(year).nc"
const PIXELS_PER_DEGREE = 20

# Years to process
const YEARS = 2000:2025

# SHA-256 of the source files used to make the artifact (downloaded 2026-11-12;
# the provider updates the latest years when it adds new ones)
const SOURCE_SHA256 = Dict(
    reverse(split(line)) for line in eachline(joinpath(@__DIR__, "source_sha256.txt"))
)

# Folder with the source files. Set YUAN_V061_DIR to reuse files downloaded
# before; otherwise they are downloaded here and removed at the end.
const SOURCE_DIR = get(ENV, "YUAN_V061_DIR", "yuan_v061_source")
const REMOVE_SOURCE = !haskey(ENV, "YUAN_V061_DIR")

# Output artifacts: directory (= artifact name), cells per degree, file suffix.
# All outputs are aggregated from 0.25° sums, so their resolution must divide 0.25°.
const OUTPUTS = [
    (dir = "modis_lai_yuan_v061_0.25deg", cells_per_degree = 4, suffix = "0.25x0.25"),
]
const SUM_CELLS_PER_DEGREE = 4

# LAI is stored as Int16 with this scale factor
const LAI_SCALE_FACTOR = 0.001f0

################################################################################
# MAIN                                                                         #
################################################################################

for out in OUTPUTS
    if isdir(out.dir)
        @warn "$(out.dir) already exists. Content will end up in the artifact and
               may be overwritten."
        @warn "Abort this calculation, unless you know what you are doing."
    else
        mkpath(out.dir)
    end
end

npix_lon, npix_lat = 360 * PIXELS_PER_DEGREE, 180 * PIXELS_PER_DEGREE
pix_lon = [-180 + (i - 0.5) / PIXELS_PER_DEGREE for i in 1:npix_lon]
pix_lat = [-90 + (j - 0.5) / PIXELS_PER_DEGREE for j in 1:npix_lat]
pix_area = Float32.(cosd.(pix_lat))
n_sum = PIXELS_PER_DEGREE ÷ SUM_CELLS_PER_DEGREE

"""
    read_source(year)

Monthly LAI of `year` on the 0.05° pixels, as a (lon, lat, month) array with
latitudes from south to north, and NaN where the source has LAI = 0 (water,
bare ground, no retrieval), as land_fraction_correction.jl expects.
"""
function read_source(year)
    path = joinpath(SOURCE_DIR, source_file(year))
    if !isfile(path)
        mkpath(SOURCE_DIR)
        @info "Downloading $(source_url(year))"
        Downloads.download(source_url(year), path)
    end
    sha = open(io -> bytes2hex(sha256(io)), path)
    sha == SOURCE_SHA256[source_file(year)] ||
        @warn "$(source_file(year)) differs from the file used to make the artifact (the provider may have updated it)" sha expected = SOURCE_SHA256[source_file(year)]
    NCDataset(path) do ds
        # The source is lai(lon, lat, time) in Julia order, latitudes from north to south
        @assert dimnames(ds["lai"]) == ("lon", "lat", "time")
        @assert ds["lon"][:] ≈ pix_lon && reverse(ds["lat"][:]) ≈ pix_lat
        @assert size(ds["lai"], 3) == 12
        lai = Float32.(coalesce.(ds["lai"][:, end:-1:1, :], NaN32))
        lai[.!(lai .> 0)] .= NaN32
        return lai
    end
end

# Pass over the years: sums of area × LAI on the 0.25° grid, and the pixels that
# are vegetated in any month of any year
lai_sums = Dict{Int, Array{Float32, 3}}()
vegetated = falses(npix_lon, npix_lat)
for year in YEARS
    @info "Aggregating $year"
    lai_year = read_source(year)
    sums = zeros(Float32, 360 * SUM_CELLS_PER_DEGREE, 180 * SUM_CELLS_PER_DEGREE, 12)
    for month in 1:12
        lai = view(lai_year, :, :, month)
        vegetated .|= .!isnan.(lai)
        weighted_block_sum!(view(sums, :, :, month), lai, pix_area, n_sum)
    end
    lai_sums[year] = sums
end

# Land fraction of each pixel from the ETOPO 30″ land-sea mask (6 × 6 values
# per pixel), and lakes from the ERA5 land fraction on 0.1° nodes
f_etopo = NCDataset(joinpath(artifact"landsea_mask_30arcseconds", "landsea_mask.nc")) do ds
    @assert ds["lon"][1] ≈ -180 + 1 / 240 && ds["lat"][1] ≈ -90 + 1 / 240
    block_mean(ds["landsea"][:, :], 6)
end
era5_land_fraction = NCDataset(joinpath(artifact"era5_land_fraction", "era5_land_fraction.nc")) do ds
    nearest_node_values(ds["lsm"][:, :], pix_lon, pix_lat)
end
f_land, f_weight = pixel_weights(f_etopo, era5_land_fraction, vegetated)
weighted_sum(f) = weighted_block_sum!(
    zeros(Float32, 360 * SUM_CELLS_PER_DEGREE, 180 * SUM_CELLS_PER_DEGREE),
    f, pix_area, n_sum,
)
area_sum, land_sum, weight_sum, etopo_sum =
    weighted_sum.((ones(Float32, npix_lon, npix_lat), f_land, f_weight, f_etopo))

for out in OUTPUTS
    k = SUM_CELLS_PER_DEGREE ÷ out.cells_per_degree
    cell_area, cell_weight, cell_etopo = block_sum.((area_sum, weight_sum, etopo_sum), k)
    land_fraction = block_sum(land_sum, k) ./ cell_area
    lon = Float32[-180 + (i - 0.5) / out.cells_per_degree for i in 1:(360 * out.cells_per_degree)]
    lat = Float32[-90 + (j - 0.5) / out.cells_per_degree for j in 1:(180 * out.cells_per_degree)]

    for year in YEARS
        lai = land_lai(block_sum(lai_sums[year], k), cell_weight, cell_etopo)
        @assert all(isfinite, lai) && 0 <= minimum(lai) && maximum(lai) < typemax(Int16) * LAI_SCALE_FACTOR

        output_path = joinpath(out.dir, "Yuan_et_al_$(year)_$(out.suffix).nc")
        NCDataset(output_path, "c") do ds
            # 2D spatially varying data over 12 months
            defDim(ds, "lon", length(lon))
            defDim(ds, "lat", length(lat))
            defDim(ds, "time", 12)

            ds.attrib["title"] = "MODIS leaf area index $year of the land part of each cell"
            ds.attrib["source"] = "Reprocessed MODIS Collection 6.1 LAI (Lin et al. 2023, Yuan et al. 2011) at 0.05° from $(source_url(year)), aggregated over land"
            ds.attrib["history"] = "Created by CliMA (see modis_lai_yuan_v061 folder in ClimaArtifacts)"

            la = defVar(ds, "lat", Float32, ("lat",))
            la.attrib["units"] = "degrees_north"
            la.attrib["standard_name"] = "latitude"
            la[:] = lat

            lo = defVar(ds, "lon", Float32, ("lon",))
            lo.attrib["units"] = "degrees_east"
            lo.attrib["standard_name"] = "longitude"
            lo[:] = lon

            # Uniform 30-day spacing, required by ClimaLand's PeriodicCalendar
            month = defVar(ds, "time", Int32, ("time",))
            month.attrib["units"] = "seconds since 1970-01-01"
            month.attrib["standard_name"] = "time"
            month.attrib["calendar"] = "proleptic_gregorian"
            month[:] = [Int32(datetime2unix(DateTime(year) + Day(30 * (k - 1)))) for k in 1:12]

            lai_var = defVar(
                ds, "lai", Int16, ("lon", "lat", "time");
                deflatelevel = 5, shuffle = true, chunksizes = (length(lon), length(lat), 1),
                attrib = ["scale_factor" => LAI_SCALE_FACTOR, "add_offset" => 0.0f0],
            )
            lai_var.attrib["units"] = "m^2 m^-2"
            lai_var.attrib["standard_name"] = "leaf_area_index"
            lai_var.attrib["long_name"] = "Leaf area index of the land part of the grid cell"
            lai_var[:, :, :] = lai

            fland_var = defVar(ds, "land_fraction", Float32, ("lon", "lat"); deflatelevel = 5, shuffle = true)
            fland_var.attrib["units"] = "1"
            fland_var.attrib["long_name"] = "Land fraction of the cell (ETOPO 2022 30 arc-second land-sea mask, lakes removed, land below sea level added)"
            fland_var[:, :] = land_fraction
        end
    end
end

# Remove the downloaded data - desired data is now stored in the CliMA artifacts
REMOVE_SOURCE && rm(SOURCE_DIR; recursive = true)

create_artifact_guided(OUTPUTS[1].dir; artifact_name = OUTPUTS[1].dir)
