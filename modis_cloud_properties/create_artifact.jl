#=
Global monthly cloud properties from MODIS (MCD06COSP_M3, collection 062):
liquid and ice water path, cloud-top particle effective radius (liquid and
ice, 3.7 micron retrieval, daytime cloudy scenes), and cloud fraction from
the cloud mask (daytime scenes).

Borbas, E., et al., 2015. MODIS Atmosphere L2 Atmosphere Profile Product.
NASA MODIS Adaptive Processing System, Goddard Space Flight Center, USA
http://dx.doi.org/10.5067/MODIS/MYD07_L2.061

Supersedes modis_lwp_iwp (same source dataset; adds reliq, reice, clt).
This script processes the MODIS data into a single file.
=#
using NCDatasets, Statistics, Dates
using ClimaArtifactsHelper

const OUTPUT_DIR = @__DIR__
const DATA_DIR = get(
    ENV,
    "MODIS_DATA_DIR",
    "/resnick/groups/esm/ClimaArtifacts/artifacts/MCD06COSP_M3_MODIS",
)
const SAMPLE_FILE = "2003/001/MCD06COSP_M3_MODIS.A2003001.062.2022168173311.nc"

# (output name, MCD06COSP group, unit conversion factor, output units,
#  short_name, long_name)
const VARIABLES = [
    (
        "lwp",
        "Cloud_Water_Path_Liquid",
        1e-3,
        "kg m-2",
        "lwp",
        "Monthly Average Liquid Water Path",
    ),
    (
        "iwp",
        "Cloud_Water_Path_Ice",
        1e-3,
        "kg m-2",
        "iwp",
        "Monthly Average Ice Water Path",
    ),
    (
        "reliq",
        "Cloud_Particle_Size_Liquid",
        1e-6,
        "m",
        "reliq",
        "Monthly Average Cloud-Top Effective Radius, Liquid (3.7 micron retrieval, daytime cloudy scenes)",
    ),
    (
        "reice",
        "Cloud_Particle_Size_Ice",
        1e-6,
        "m",
        "reice",
        "Monthly Average Cloud-Top Effective Radius, Ice (3.7 micron retrieval, daytime cloudy scenes)",
    ),
    (
        "clt",
        "Cloud_Mask_Fraction",
        1.0,
        "unitless",
        "clt",
        "Monthly Average Cloud Fraction from Cloud Mask (daytime scenes)",
    ),
]

# Read sample file to get dimension variables and per-group attributes.
ds = Dataset(joinpath(DATA_DIR, SAMPLE_FILE), "r")
lat = ds["latitude"][:]
lon = ds["longitude"][:]

ntimes = 0
for yr in filter(x -> isdir(joinpath(DATA_DIR, x)), readdir(DATA_DIR))
    days = readdir(joinpath(DATA_DIR, yr))
    global ntimes += length(days)
end

ds_out =
    Dataset(joinpath(OUTPUT_DIR, "modis_cloud_properties.nc"), "c", attrib = ds.attrib)

ds_out.attrib["processing_date"] = string(Dates.now())
ds_out.attrib["processing_note"] =
    "Combined monthly averages from MODIS MCD06COSP_M3 data. " *
    "Units converted to SI (water paths g m-2 -> kg m-2, effective radii " *
    "microns -> m); cloud fraction kept as a 0-1 fraction."
ds_out.attrib["history"] =
    "Modified by CliMA for coupled model data assimilation. " *
    "Based on original data provided by NASA MODIS."

defDim(ds_out, "time", ntimes)
defDim(ds_out, "latitude", length(lat))
defDim(ds_out, "longitude", length(lon))

time_var = defVar(
    ds_out,
    "time",
    Float64,
    ("time",),
    attrib = Dict("units" => "seconds since 2002-07-01 00:00:00"),
)
lat_var = defVar(
    ds_out,
    "latitude",
    Float64,
    ("latitude",),
    attrib = copy(ds["latitude"].attrib),
)
lon_var = defVar(
    ds_out,
    "longitude",
    Float64,
    ("longitude",),
    attrib = copy(ds["longitude"].attrib),
)

out_vars = Dict{String, Any}()
for (name, group_name, factor, units, short_name, long_name) in VARIABLES
    attrib = copy(NCDatasets.group(ds, group_name)["Mean"].attrib)
    attrib["units"] = units
    attrib["short_name"] = short_name
    attrib["long_name"] = long_name
    out_vars[name] =
        defVar(ds_out, name, Float64, ("time", "latitude", "longitude"), attrib = attrib)
end

lat_var[:] = lat
lon_var[:] = lon

start_date = Date(2002, 7, 1)
ntime = 1
times = Float64[]
# Each yr is a year 2002 - 2025, each day is the 001 - 336 within the year.
for yr in filter(x -> isdir(joinpath(DATA_DIR, x)), readdir(DATA_DIR))
    days = readdir(joinpath(DATA_DIR, yr))
    for d in days
        input_file = first(readdir(joinpath(DATA_DIR, yr, d)))
        current_ds = Dataset(joinpath(DATA_DIR, yr, d, input_file), "r")

        for (name, group_name, factor, _, _, _) in VARIABLES
            data = NCDatasets.group(current_ds, group_name)["Mean"] |> Array
            replace!(data, (missing => NaN))
            out_vars[name][ntime, :, :] = data .* factor
        end
        close(current_ds)

        current_date = Date(parse(Int, yr)) + Day(parse(Int, d) - 1)
        println(current_date)
        time_diff_days = Dates.value(Day(current_date - start_date))
        push!(times, time_diff_days * 86_400.0)

        global ntime += 1
    end
end

time_var[:] = times

close(ds_out)
close(ds)

create_artifact_guided(OUTPUT_DIR; artifact_name = basename(@__DIR__))
