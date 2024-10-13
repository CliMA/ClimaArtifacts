# Global clumping index data derived from MODIS data by
# He, L., J.M. Chen, J. Pisek, C. Schaaf, and A.H. Strahler. 2017. 
# Global 500-m Foliage Clumping Index Data Derived from MODIS BRDF, 2006.
# ORNL DAAC, Oak Ridge, Tennessee, USA. https://doi.org/10.3334/ORNLDAAC/1531

# We will use GriddingMachine.jl to fetch and process the MODIS CI data into the
# desired format for consumption by the Land model:
# Y. Wang, P. Köhler, R. K. Braghiere, M. Longo, R. Doughty, A. A. Bloom, and
# C. Frankenberg. 2022. GriddingMachine, a database and software for Earth
# system modeling at global and regional scales. Scientific Data. 9: 258
# https://doi.org/10.1038/s41597-022-01346-x

################################################################################
# IMPORTS                                                                      #
################################################################################

using NCDatasets

using GriddingMachine.Collector
using GriddingMachine.Indexer
using GriddingMachine.Blender

using ClimaArtifactsHelper

################################################################################
# CONSTANTS                                                                    #
################################################################################

# Dataset name to be fetched via the GriddingMachine
MODIS_CI_DATASET = "2X_1Y_V1"

# Output directory
OUTPUT_DIR = "modis_clumping_index"

# Output nc file name
OUTPUT_FILE = "He_et_al_2012_1x1.nc"

# Resolution of the simulation
RESOLUTION = 1

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

# Download the CI data as a julia artifact.
ci_collector  = Collector.clumping_index_collection()
download_path = Collector.query_collection(ci_collector, MODIS_CI_DATASET)

# Read the data from the dowloaded nc file
ci_data = Indexer.read_LUT(download_path)

# Regrid the data to the desired simulation resolution - 1x1 degree. Note that 
# the regridder will require integer trucation of the divider (1/R)
ci_data_regridded = Blender.regrid(ci_data[1], Int64(1 / RESOLUTION))

# Get the original the lat/lon vectors of the dataset so that we may compute the
# lat/lon of the regridded data.
orig_data = NCDataset(download_path, "r")
orig_lat = orig_data["lat"][:]
orig_lon = orig_data["lon"][:]
close(orig_data)

# Since we regridded to half of the resolution of the original data, we need to 
# average every 2 lat/lon points to get the lat/lon of the regridded data.
out_lon = (orig_lon[1:2:end] .+ orig_lon[2:2:end]) ./ 2
out_lat = (orig_lat[1:2:end] .+ orig_lat[2:2:end]) ./ 2

# Write the regridded data to the output directory
output_path = joinpath(OUTPUT_DIR, OUTPUT_FILE)
ds          = NCDataset(output_path, "c")

# Define the dimensions of the data -> 2D spatially varying data
defDim(ds, "lon", size(ci_data_regridded)[1])
defDim(ds, "lat", size(ci_data_regridded)[2])

# Define the variables of the data - lat, lon, and the clumping index
la     = defVar(ds, "lat", Float32, ("lat",))
lo     = defVar(ds, "lon", Float32, ("lon",))
ci_var = defVar(ds, "ci", Float32, ("lon", "lat"))

# Set the attributes of the variables. Clumping index is unitless.
la.attrib["units"]             = "degrees_north"
la.attrib["standard_name"]     = "latitude"
lo.attrib["units"]             = "degrees_east"
lo.attrib["standard_name"]     = "longitude"
ci_var.attrib["units"]         = "unitless"
ci_var.attrib["standard_name"] = "Foliage Clumping Index"

# Write the data for each variable out to the nc file
la[:]     = out_lat
lo[:]     = out_lon
ci_var[:, :] = ci_data_regridded
close(ds)

# Remove the initial downloaded artifact file - desired data is now stored in 
# the CliMA artifact.
Collector.clean_collections!(ci_collector)

create_artifact_guided(OUTPUT_DIR; artifact_name = basename(@__DIR__))
