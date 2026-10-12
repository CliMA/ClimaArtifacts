# Global LAI data derived from MODIS data by
# Yuan, Hua and Dai, Yongjiu and Xiao, Zhiqiang and Ji, Duoying and Shangguan,
# Wei, 2011. Reprocessing the MODIS Leaf Area Index products for land surface
# and climate modelling.

# We use GriddingMachine.jl to fetch the MODIS LAI data at 0.05° and aggregate
# it to the 1° and 0.25° grids consumed by the Land model:
# Y. Wang, P. Köhler, R. K. Braghiere, M. Longo, R. Doughty, A. A. Bloom, and
# C. Frankenberg. 2022. GriddingMachine, a database and software for Earth
# system modeling at global and regional scales. Scientific Data. 9: 258
# https://doi.org/10.1038/s41597-022-01346-x

# The GriddingMachine data averages water as LAI = 0, so we aggregate the 0.05°
# pixels over land only, using the ETOPO 30″ land fraction of each pixel (see
# land_fraction_correction.jl and the README).

################################################################################
# IMPORTS                                                                      #
################################################################################

using Artifacts
using NCDatasets
using Dates

using GriddingMachine.Collector

using ClimaArtifactsHelper

include("land_fraction_correction.jl")

################################################################################
# CONSTANTS                                                                    #
################################################################################

# Source dataset: monthly LAI at 0.05° (20 pixels per degree)
dataset_name(year) = "MODIS_20X_1M_$(year)_V1"
const PIXELS_PER_DEGREE = 20

# Years to fetch
const YEARS = 2000:2020

# Output artifacts: directory (= artifact name), cells per degree, file suffix.
# All outputs are aggregated from 0.25° sums, so their resolution must divide 0.25°.
const OUTPUTS = [
    (dir = "modis_lai", cells_per_degree = 1, suffix = "1x1"),
    (dir = "modis_lai_0.25deg", cells_per_degree = 4, suffix = "0.25x0.25"),
]
const SUM_CELLS_PER_DEGREE = 4

# LAI is stored as Int16 with this scale factor: the source precision is 0.1
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
        mkdir(out.dir)
    end
end

npix_lon, npix_lat = 360 * PIXELS_PER_DEGREE, 180 * PIXELS_PER_DEGREE
pix_lon = [-180 + (i - 0.5) / PIXELS_PER_DEGREE for i in 1:npix_lon]
pix_lat = [-90 + (j - 0.5) / PIXELS_PER_DEGREE for j in 1:npix_lat]
pix_area = Float32.(cosd.(pix_lat))
n_sum = PIXELS_PER_DEGREE ÷ SUM_CELLS_PER_DEGREE

# Pass over the years: sums of area × LAI on the 0.25° grid, and the pixels that
# are vegetated in any month of any year
lai_collector = Collector.lai_collection()
lai_sums = Dict{Int, Array{Float32, 3}}()
vegetated = falses(npix_lon, npix_lat)
for year in YEARS
    @info "Aggregating $year"
    download_path = Collector.query_collection(lai_collector, dataset_name(year))
    NCDataset(download_path) do ds
        @assert ds["lon"][:] ≈ pix_lon && ds["lat"][:] ≈ pix_lat
        sums = zeros(Float32, 360 * SUM_CELLS_PER_DEGREE, 180 * SUM_CELLS_PER_DEGREE, 12)
        for month in 1:12
            lai = ds["data"][:, :, month]
            vegetated .|= .!isnan.(lai)
            weighted_block_sum!(view(sums, :, :, month), lai, pix_area, n_sum)
        end
        lai_sums[year] = sums
    end
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
            ds.attrib["source"] = "Yuan et al. (2011) MODIS LAI at 0.05° from GriddingMachine.jl ($(dataset_name(year))), aggregated over land"
            ds.attrib["history"] = "Created by CliMA (see modis_lai folder in ClimaArtifacts)"

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
Collector.clean_collections!(lai_collector)

create_artifact_guided(OUTPUTS[1].dir; artifact_name = OUTPUTS[1].dir)
create_artifact_guided(OUTPUTS[2].dir; artifact_name = OUTPUTS[2].dir, append = true)
