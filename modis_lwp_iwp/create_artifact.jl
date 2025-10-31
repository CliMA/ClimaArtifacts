#= 
Global Liquid and Ice Water Path data from MODIS
Borbas, E., et al., 2015. MODIS Atmosphere L2 Atmosphere Profile Product. 
NASA MODIS Adaptive Processing System, Goddard Space Flight Center, USA
http://dx.doi.org/10.5067/MODIS/MYD07_L2.061

This script processes the MODIS data into a single file.
=#
using NCDatasets, Statistics, Dates
using ClimaArtifactsHelper

const OUTPUT_DIR = @__DIR__
const DATA_DIR = "/resnick/groups/esm/ClimaArtifacts/artifacts/MCD06COSP_M3_MODIS"
const SAMPLE_FILE = "2003/001/MCD06COSP_M3_MODIS.A2003001.062.2022168173311.nc"

# Read sample file to get dimension variables
ds = Dataset(joinpath(DATA_DIR, SAMPLE_FILE), "r")
lat = ds["latitude"][:]
lon = ds["longitude"][:]

# Get attributes from the groups for lwp and iwp
lwp_group = NCDatasets.group(ds, "Cloud_Water_Path_Liquid")
iwp_group = NCDatasets.group(ds, "Cloud_Water_Path_Ice")
lwp_attrib = copy(lwp_group["Mean"].attrib)
iwp_attrib = copy(iwp_group["Mean"].attrib)

# Modify units since we're converting from g m-2 to kg m-2
lwp_attrib["units"] = "kg m-2"
iwp_attrib["units"] = "kg m-2"

# Add short_name and long_name for clarity
lwp_attrib["short_name"] = "lwp"
lwp_attrib["long_name"] = "Monthly Average Liquid Water Path"
iwp_attrib["short_name"] = "iwp"
iwp_attrib["long_name"] = "Monthly Average Ice Water Path"

ntimes = 0
for yr in filter(isdir, readdir(DATA_DIR))
    days = readdir(joinpath(DATA_DIR, yr))
    global ntimes += length(days)
end

ds_out = Dataset(joinpath(OUTPUT_DIR, "modis_lwp_iwp.nc"), "c", attrib = ds.attrib)

# Add or update global attributes to reflect processing
ds_out.attrib["processing_date"] = string(Dates.now())
ds_out.attrib["processing_note"] = "Combined monthly averages from MODIS MCD06COSP_M3 data, units converted from g m-2 to kg m-2"
ds_out.attrib["history"] = "Modified by CliMA for coupled model data assimilation. Based on original data provided by NASA MODIS."

# Define dimensions
defDim(ds_out, "time", ntimes)
defDim(ds_out, "latitude", length(lat))
defDim(ds_out, "longitude", length(lon))

# Define variables
time_var = defVar(ds_out, "time", Float64, ("time",), attrib = Dict("units" => "seconds since 2002-07-01 00:00:00"))
lat_var = defVar(ds_out, "latitude", Float64, ("latitude",), attrib = copy(ds["latitude"].attrib))
lon_var = defVar(ds_out, "longitude", Float64, ("longitude",), attrib = copy(ds["longitude"].attrib))
lwp_var = defVar(ds_out, "lwp", Float64, ("time", "latitude", "longitude"), attrib = lwp_attrib)
iwp_var = defVar(ds_out, "iwp", Float64, ("time", "latitude", "longitude"), attrib = iwp_attrib)

# Assign coordinate values
lat_var[:] = lat
lon_var[:] = lon

# Loop over all files in dataset, concatenating data into one artifact file
start_date = Date(2002, 7, 1)
ntime = 1
times = Float64[]
# Each yr is a year 2002 - 2025, each day is the 001 - 336 within the year
for yr in filter(x -> isdir(joinpath(DATA_DIR, x)), readdir(DATA_DIR))
    days = readdir(joinpath(DATA_DIR, yr))
    for d in days
        input_file = first(readdir(joinpath(DATA_DIR, yr, d)))
        current_ds = Dataset(joinpath(DATA_DIR, yr, d, input_file), "r")

        group = NCDatasets.group(current_ds, "Cloud_Water_Path_Liquid")
        lwp_mean = group["Mean"] |> Array
        replace!(lwp_mean, (missing => NaN))
        # Convert from g m-2 to kg m-2
        lwp_var[ntime, :, :]  = lwp_mean ./ 1000.0

        group = NCDatasets.group(current_ds, "Cloud_Water_Path_Ice")
        iwp_mean = group["Mean"] |> Array
        replace!(iwp_mean, (missing => NaN))
        # Convert from g m-2 to kg m-2
        iwp_var[ntime, :, :]  = iwp_mean ./ 1000.0

        # Compute time in seconds since start_date
        current_date = Date(parse(Int, yr)) + Day(parse(Int, d) - 1)
        println(current_date)
        # Convert to seconds: difference in days * 86400 seconds/day
        time_diff_days = Dates.value(Day(current_date - start_date))
        push!(times, time_diff_days * 86_400.0)

        global ntime += 1

    end
end

time_var[:] = times

close(ds_out)
close(ds)

create_artifact_guided(OUTPUT_DIR; artifact_name = basename(@__DIR__))
