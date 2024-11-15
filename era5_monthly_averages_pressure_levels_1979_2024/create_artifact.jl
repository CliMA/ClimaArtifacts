using Downloads
using ClimaArtifactsHelper
using NCDatasets
using Dates

const DATA_DIR = "/net/sampo/data1/era5/monthly-avg-pressure-levels"
const DOWNLOADED_DATA_PATH = joinpath(DATA_DIR, "single_years/")
const OUTPUT_FILE_NAME = "era5_monthly_averages_pressure_levels_197901-202410.nc"
const OUTPUT_DIR = joinpath(DATA_DIR, basename(@__DIR__) * "_artifact")

if isdir(OUTPUT_DIR)
    @warn "$OUTPUT_DIR already exists. Content will end up in the artifact and may be overwritten."
    @warn "Abort this calculation, unless you know what you are doing."
else
    mkdir(OUTPUT_DIR)
end

year_paths = [joinpath(DOWNLOADED_DATA_PATH, string(year) * ".nc") for year = 1979:2024]

if !all(isfile, year_paths)
    @info "Data for 1979-2024 not found in $DOWNLOADED_DATA_PATH, downloading and populatinit (might take a while)"
    if isfile(homedir() * "/.cdsapirc")
        run(`python download_era5.py -d $DOWNLOADED_DATA_PATH`)
    else
        println("Enter your CDS Personal Access Token:")
        cds_PAT = readline()
        println("Downloading data with CDS API using PAT: $cds_PAT")
        run(`python download_era5.py -k $cds_PAT -d $DOWNLOADED_DATA_PATH`)
    end
end

@info "Processing data"

input_ds = NCDataset(year_paths; aggdim = "date", deferopen = false)
output_path = joinpath(OUTPUT_DIR, OUTPUT_FILE_NAME)

if isfile(output_path)
    rm(output_path)
    @info "Removed existing file $output_path"
end
output_ds = NCDataset(output_path, "c")
for (attrib_name, attrib_value) in input_ds.attrib
    output_ds.attrib[attrib_name] = attrib_value
end

defDim(output_ds, "longitude", input_ds.dim["longitude"])
defDim(output_ds, "latitude", input_ds.dim["latitude"])
defDim(output_ds, "time", input_ds.dim["date"])
defDim(output_ds, "pressure_level", input_ds.dim["pressure_level"])

# The coordinates attribute is incorrect in the original data
# the _FillValue attribute is automatically added by NCDatasets
ignored_attribs =
    ["_FillValue", "missing_value", "add_offset", "scale_factor", "coordinates"]


deflatelevel = 9 # max compression (lossless)
for (varname, var) in input_ds
    if !(varname in ["longitude", "latitude", "date", "pressure_level", "number", "expver"])
        attrib = copy(var.attrib)
        for (key, value) in attrib
            if key in ignored_attribs || occursin("GRIB", key) || attrib[key] == "unknown"
                delete!(attrib, key)
            end
        end
        # store everything as Float32 to save space
        # reverse the pressure and latitude dimensions to have them in ascending order
        defVar(
            output_ds,
            varname,
            Float32.(reverse(reverse(var[:, :, :, :], dims = 2), dims = 3)),
            (dimnames(var)[1:3]..., "time");
            attrib = attrib,
            deflatelevel = deflatelevel,
        )
    end
end
defVar(
    output_ds,
    "expver",
    input_ds["expver"][:],
    ("time",);
    attrib = input_ds["expver"].attrib,
)
# reverse the latitude dimension to have it in ascending order
defVar(
    output_ds,
    "latitude",
    reverse(input_ds["latitude"][:]),
    ("latitude",);
    attrib = delete!(copy(input_ds["latitude"].attrib), "stored_direction"),
)

defVar(
    output_ds,
    "longitude",
    input_ds["longitude"][:],
    ("longitude",);
    attrib = input_ds["longitude"].attrib,
)

pressure_attrib = copy(input_ds["pressure_level"].attrib)
pressure_attrib["stored_direction"] = "increasing"
pressure_attrib["units"] = "Pa"
delete!(pressure_attrib, "positive")
# convert pressure to Pa and reverse the pressure dimension to have it in ascending order
defVar(
    output_ds,
    "pressure_level",
    reverse(input_ds["pressure_level"][:] .* 100),
    ("pressure_level",);
    attrib = pressure_attrib,
)
# If data is requested as netcdf, and not netcdf_legacy, the data includes a date dimension
# instead of time, where each date is an integer in the format yyyymmdd.
# Here we convert it to a DateTime object, and set the day to the 15th of the month.

new_times = map(input_ds["date"][:]) do t
    d = DateTime(string(t), "yyyymmdd")
    d + (Day(15) - Day(d))
end

# check that there are no duplicates and that it is sorted
@assert issorted(new_times)
for i = 2:length(new_times)
    @assert new_times[i] != new_times[i-1]
end

new_times_attribs = ["standard_name" => "time", "long_name" => "Time"]

defVar(output_ds, "time", new_times, ("time",); attrib = new_times_attribs)

close(output_ds)
close(input_ds)

create_artifact_guided(
    OUTPUT_DIR;
    artifact_name = basename(@__DIR__),
)
