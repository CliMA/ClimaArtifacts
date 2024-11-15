using NCDatasets
using Statistics
using ClimaArtifactsHelper

if length(ARGS) < 1
    @error("Please provide the local path to the raw data nc file.")
else
    nc_path = ARGS[1]
end

outputdir = "topmodel"
if isdir(outputdir)
    @warn "$outputdir already exists. Content will end up in the artifact and may be overwritten."
    @warn "Abort this calculation, unless you know what you are doing."
else
    mkdir(outputdir)
end

include("utils.jl")

"""
    create_artifact(nc_path, resolution, attribs, statistics, outfile_path)

This function reads in the raw data at `nc_path` and computes a set of
statistics at a resolution, in degrees, of `resolution`. These statistics are
supplied as a list of functions `statistics` of the form x::AbstractArray -> f(x)::Float.

The computed statistics are then saved as an NetCDF file to `outfile_path`, with the `attribs`
given. The attribs include global attribs for the file, as well as attribs (varname, varlongname, varunits)
for each statistic computed.

For example, if you would like to create a map of the mean topographic index at 1 degree resolution, 
you could do:
nc_path = path_to_raw_data.nc
outfile_path = path_to_statistics.nc
resolution = 1.0
statistics = (x -> mean(x),)
var_attribs = ((; varlongname = "The mean topographic index",
                varunits = "unitless",
                varname = "ti_mean",
                ),)
attribs = (; global attrib, var_attribs)
create_artifact(nc_path, resolution, attribs, statistics, outfile_path)
"""
function create_artifact(nc_path, resolution, attribs, statistics, outfile_path)
    data = NCDataset(nc_path)
    lat = data["lat"][:];
    lon = data["lon"][:];
    ti = data["Band1"][:,:];
    close(data)
    
    outdata, outlat, outlon =
        regrid_and_compute_statistics(ti, (lon, lat), resolution, statistics);
    write_nc_out(outdata, outlat, outlon, attribs, outfile_path)
    Base.mv(outfile_path, joinpath(outputdir, outfile_path))
end
# Simulation Resolution
resolution = 1.0 # degree
# What we want to use to aggregate the topographic index values in the resolution x resolution grid boxes
statistics = ((x) -> sum(x .> mean(x)) ./ length(x), (x) -> 1)
outfile_path = "topographic_index_statistics_$(resolution)x$(resolution).nc"
data = NCDataset(nc_path)
global_attrib = copy(data.attrib)
close(data)

var_attribs = ((;
                varlongname = "The maximum saturated fraction from TOPMODEL",
                varunits = "unitless",
                varname = "fmax",
                ),
               (;
                varlongname = "Land sea mask estimated from topographic index map",
                varunits = "unitless",
                varname = "landsea_mask",
                ),
               )
               
create_artifact(nc_path, resolution, (;global_attrib, var_attribs), statistics, outfile_path)

create_artifact_guided(outputdir; artifact_name = basename(@__DIR__))
