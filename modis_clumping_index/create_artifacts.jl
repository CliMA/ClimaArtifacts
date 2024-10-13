# Global clumping index data derived from MODIS data by
# He, L., J.M. Chen, J. Pisek, C. Schaaf, and A.H. Strahler. 2017. 
# Global 500-m Foliage Clumping Index Data Derived from MODIS BRDF, 2006.
# ORNL DAAC, Oak Ridge, Tennessee, USA. https://doi.org/10.3334/ORNLDAAC/1531

# First, download the clumping index data derived from MODIS at 
# https://daac.ornl.gov/cgi-bin/dsviewer.pl?ds_id=1531 and put the path to that
# your local copy of that data in the TIFF_PATH constant below.

using NCDatasets
using ClimaArtifactsHelper

TIFF_PATH = missing

outputdir = "clumping_index_artifacts"
if isdir(outputdir)
    @warn "$outputdir already exists. Content will end up in the artifact
            and may be overwritten."
    @warn "Abort this calculation, unless you know what you are doing."
else
    mkdir(outputdir)
end

# Use the process_tiff python script to reproject the geotiff data to lat/long
# from sinusoidal coordinates and save the result to a netcdf file. The nc file 
# is now stored in this directory at clumping_index.nc
@assert(success(`python3 process_tif.py $TIFF_PATH`))

# Utilities for regridding and working with ncdatasets
include("utils.jl")

# Get the lat/long from the nc data
nc_data = NCDatasets.NCDataset("clumping_index.nc")
lat = nc_data["lat"][:];
lon = nc_data["lon"][:];

# Empty data array
data = Array{Union{Missing, Float32}}(missing, length(lon), length(lat))

# Simulation Resolution
resolution = 1.0

# Function which reads in the data, regrids to the simulation grid, writes the file to the correct output location.
function create_artifact(data, files, attrib, transform, outfilepath)
    # get parameter values at each layer
    read_nc_data!(data, files, filedir)
    outdata, outlat, outlon =
        regrid(data, (lon, lat), resolution, transform, nlayers)
    write_nc_out(outdata, outlat, outlon, z, attrib, outfilepath)
    Base.mv(outfilepath, joinpath(outputdir, outfilepath))
end

# Process clumping index
files = ["clumping_index.nc"]

transform(x) = x # CI already in correct units
outfilepath = "clumping_index_map_he_etal2017_$(resolution)x$(resolution)x1.nc"
attrib = (;
    vartitle = "Foliage Clumping Index",
    varunits = "unitless",
    varname = "ci",
)
create_artifact(data, files, attrib, transform, outfilepath)

create_artifact_guided(outputdir; artifact_name=basename(@__DIR__))

# Now we are done with the intermediate nc file and can remove it
rm("clumping_index.nc")
