# Global LAI data derived from MODIS data by
# Yuan, Hua and Dai, Yongjiu and Xiao, Zhiqiang and Ji, Duoying and Shangguan,
# Wei, 2011. Reprocessing the MODIS Leaf Area Index products for land surface
# and climate modelling.

# We will use GriddingMachine.jl to fetch and process the MODIS LAI data into 
# the desired format for consumption by the Land model:
# Y. Wang, P. Köhler, R. K. Braghiere, M. Longo, R. Doughty, A. A. Bloom, and
# C. Frankenberg. 2022. GriddingMachine, a database and software for Earth
# system modeling at global and regional scales. Scientific Data. 9: 258
# https://doi.org/10.1038/s41597-022-01346-x

# The GriddingMachine data averages water pixels as LAI = 0, so we divide out
# the ERA5 land fraction to obtain the LAI of the land part of each cell
# (see land_fraction_correction.jl and the README).

################################################################################
# IMPORTS                                                                      #
################################################################################

using Artifacts
using NCDatasets
using Dates

using GriddingMachine.Collector
using GriddingMachine.Indexer
using GriddingMachine.Blender

using ClimaArtifactsHelper

include("land_fraction_correction.jl")

################################################################################
# CONSTANTS                                                                    #
################################################################################

# Dataset to be fetched via the GriddingMachine
MODIS_LAI_DATASET_PREFIX = "MODIS_2X_1M_"
MODIS_LAI_DATASET_SUFFIX = "_V1"

# Output directory
OUTPUT_DIR = "modis_lai"

# Output nc file name
OUTPUT_FILE_PREFIX = "Yuan_et_al_"

# Output nc file name suffix
OUTPUT_FILE_SUFFIX = "_1x1.nc"

# Output data resolution
RESOLUTION = 1

# Years to fetch
YEARS = range(2000, 2020)

################################################################################
# MAIN                                                                         #
################################################################################

if isdir(OUTPUT_DIR)
    @warn "$OUTPUT_DIR already exists. Content will end up in the artifact and
           may be overwritten."
    @warn "Abort this calculation, unless you know what you are doing."
else
    mkdir(OUTPUT_DIR)
end

# ERA5 land fraction on 0.1° nodes, used to correct the LAI of partially land cells
lsm = NCDataset(joinpath(artifact"era5_land_fraction", "era5_land_fraction.nc")) do ds
    Float64.(ds["lsm"][:, :])
end

for year in YEARS
    # Dataset to be fetched via the GriddingMachine
    MODIS_LAI_DATASET = MODIS_LAI_DATASET_PREFIX * string(year) *
                         MODIS_LAI_DATASET_SUFFIX

    # Output nc file name
    OUTPUT_FILE = OUTPUT_FILE_PREFIX * string(year) * OUTPUT_FILE_SUFFIX

    # Download the LAI data as a julia artifact.
    lai_collector  = Collector.lai_collection()
    download_path = Collector.query_collection(lai_collector, MODIS_LAI_DATASET)

    # Read the data from the dowloaded nc file
    lai_data = Indexer.read_LUT(download_path)

    # Regrid the data to the desired simulation resolution - 1x1 degree. Note
    # that the regridder will require integer trucation of the divider (1/R)
    lai_data_regridded = Blender.regrid(lai_data[1], Int64(1 / RESOLUTION))

    # Get the original the lat/lon vectors of the dataset so that we may compute
    # the lat/lon of the regridded data.
    orig_data = NCDataset(download_path, "r")
    orig_lat = orig_data["lat"][:]
    orig_lon = orig_data["lon"][:]
    close(orig_data)

    # Convert all NANs (cells without any land pixel) to 0.0, as the source data
    # does for water pixels
    lai_data_regridded .= ifelse.(isnan.(lai_data_regridded), 0.0f0,
                                                             lai_data_regridded)

    # Since we regridded to half of the resolution of the original data, we need
    # to average every 2 lat/lon points to get the lat/lon of the regridded
    # data.
    out_lon = (orig_lon[1:2:end] .+ orig_lon[2:2:end]) ./ 2
    out_lat = (orig_lat[1:2:end] .+ orig_lat[2:2:end]) ./ 2

    # Recover the LAI of the land part of each cell
    fland = cell_land_fraction(lsm, out_lon, out_lat)
    lai_data_regridded = land_fraction_corrected(lai_data_regridded, fland)

    # Write the regridded data to the output directory
    output_path = joinpath(OUTPUT_DIR, OUTPUT_FILE)
    ds          = NCDataset(output_path, "c")

    # Define the dimensions of the data -> 2D spatially varying data over 12
    # months
    defDim(ds, "lon", size(lai_data_regridded)[1])
    defDim(ds, "lat", size(lai_data_regridded)[2])
    defDim(ds, "time", 12)

    # Define the variables of the data - lat, lon, and the lai
    la      = defVar(ds, "lat", Float32, ("lat",))
    lo      = defVar(ds, "lon", Float32, ("lon",))
    month   = defVar(ds, "time", Int32, ("time",))
    lai_var = defVar(ds, "lai", Float32, ("lon", "lat", "time"))
    fland_var = defVar(ds, "land_fraction", Float32, ("lon", "lat"))

    # Set the attributes of the variables.
    la.attrib["units"]              = "degrees_north"
    la.attrib["standard_name"]      = "latitude"
    lo.attrib["units"]              = "degrees_east"
    lo.attrib["standard_name"]      = "longitude"
    month.attrib["units"]           = "seconds since 1970-01-01"
    month.attrib["standard_name"]   = "time"
    month.attrib["calendar"]        = "proleptic_gregorian"
    lai_var.attrib["units"]         = "m^2 m^-2"
    lai_var.attrib["standard_name"] = "Leaf area index"
    lai_var.attrib["long_name"]     = "Leaf area index of the land part of the grid cell"
    fland_var.attrib["units"]       = "1"
    fland_var.attrib["long_name"]   = "ERA5 land fraction used for the correction"

    # Write the data for each variable out to the nc file
    la[:]     = out_lat
    lo[:]     = out_lon
    
    # Data from the gridding machhine is month (1:1:12), and we need to convert
    # to DateTime format for the time variable so that we can use the
    # periodicCalendar calendar boundary condition in the Land model.
    # Note that even spacing on the timestamps is required for the
    # periodicCalendar boundary condition
    times     = [DateTime(year, 1, 1) + Dates.Day(30 * (k - 1)) for k in 1:12]
    month[:]  = Int32.([Dates.datetime2unix(t) for t in times])
    lai_var[:, :, :] = lai_data_regridded
    fland_var[:, :] = fland
    close(ds)

    # Remove the initial downloaded artifact file - desired data is now stored
    # in the CliMA artifact.
    Collector.clean_collections!(lai_collector)
end

create_artifact_guided(OUTPUT_DIR; artifact_name = basename(@__DIR__))
