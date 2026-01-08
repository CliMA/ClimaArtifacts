using Downloads
using ClimaArtifactsHelper
using NCDatasets

# ERA5 land-sea mask (lsm) at 0.1° resolution
# Source: ECMWF ERA5 reanalysis
# The raw file has dimensions (time, latitude, longitude) with a singleton time dimension
# and latitude potentially in descending order (90 -> -90).
#
# This script preprocesses the data to:
#   1. Remove the singleton time dimension
#   2. Ensure latitude is in ascending order (-90 -> 90)
#   3. Handle fill values by replacing with NaN
#   4. Output a clean 2D (lon, lat) NetCDF file suitable for SpaceVaryingInput

# The raw ERA5 file can be obtained from:
# https://confluence.ecmwf.int/download/attachments/140385202/lsm_1279l4_0.1x0.1.grb_v4_unpack.nc?version=1&modificationDate=1591983422208&api=v2
# documentation for all era5-land vars: https://confluence.ecmwf.int/display/CKB/ERA5-Land%3A+data+documentation
# Variable: "Land-sea mask" (lsm)
const FILE_URL = "https://confluence.ecmwf.int/download/attachments/140385202/lsm_1279l4_0.1x0.1.grb_v4_unpack.nc?version=1&modificationDate=1591983422208&api=v2"
const FILE_PATH_RAW = "lsm_1279l4_0.1x0.1.grb_v4_unpack.nc"

output_dir = basename(@__DIR__) * "_artifact"
if isdir(output_dir)
    @warn "$output_dir already exists. Content will end up in the artifact and may be overwritten."
    @warn "Abort this calculation, unless you know what you are doing."
else
    mkdir(output_dir)
end

# Download or use local file
if !isfile(FILE_PATH_RAW)
    @info "$FILE_PATH_RAW not found, downloading it (might take a while)"
    downloaded_file = Downloads.download(FILE_URL; progress = download_rate_callback())
    Base.mv(downloaded_file, FILE_PATH_RAW)
end

outfile_path = joinpath(output_dir, "era5_land_fraction.nc")

"""
    preprocess_era5_land_fraction(infile, outfile)

Preprocess ERA5 land-sea mask file to create a clean 2D NetCDF file.

The raw ERA5 lsm file typically has:
- Dimensions: (time, latitude, longitude) with time being a singleton
- Latitude in descending order (90 -> -90)
- Possible fill values

1. Reverses latitude to ascending order if needed
2. Replaces fill values with NaN
3. Writes a clean 2D (lon, lat) NetCDF file
"""
function preprocess_era5_land_fraction(infile, outfile)
    NCDataset(infile) do ncin
        # Read coordinate arrays
        # ERA5 files may use "longitude"/"latitude" or "lon"/"lat"
        lon_name = "longitude" in keys(ncin) ? "longitude" : "lon"
        lat_name = "latitude" in keys(ncin) ? "latitude" : "lat"
        
        lon_in = Array(ncin[lon_name][:])
        lat_in = Array(ncin[lat_name][:])
        lsm_var = ncin["lsm"]

        # For the ERA5 land-sea mask file, `lsm` is static but stored with a singleton
        # time dimension. In Julia/NCDatasets this appears as `lsm(lon, lat, time)`.
        dims = dimnames(lsm_var)
        (length(dims) == 3 && dims[end] == "time") ||
            error("Expected `lsm` dims to be (lon, lat, time); got $(dims)")
        size(lsm_var, 3) == 1 || @warn "Expected singleton time dimension, got size(time) = $(size(lsm_var, 3))"

        lsm_lonlat = Array(lsm_var[:, :, 1])

        (size(lsm_lonlat, 1) == length(lon_in) && size(lsm_lonlat, 2) == length(lat_in)) ||
            error(
                "Unexpected `lsm` size after slicing time: got $(size(lsm_lonlat)), expected (lon,lat)=($(length(lon_in)),$(length(lat_in)))",
            )

        # Replace fill values with NaN so downstream isfinite/clamping handles them
        fill = get(lsm_var.attrib, "_FillValue", nothing)
        if !isnothing(fill)
            lsm_lonlat[lsm_lonlat .== fill] .= NaN
        end

        # ERA5 files have latitude decreasing (90 -> -90). Ensure increasing
        # latitude to avoid issues in downstream interpolation.
        if issorted(lat_in; rev = true)
            @info "Reversing latitude to ascending order"
            lat_in = reverse(lat_in)
            lsm_lonlat = reverse(lsm_lonlat; dims = 2)  # reverse latitude dim
        end

        # Write preprocessed file
        NCDataset(outfile, "c") do ncout
            defDim(ncout, "lon", length(lon_in))
            defDim(ncout, "lat", length(lat_in))

            lon = defVar(ncout, "lon", Float32, ("lon",); deflatelevel = 9)
            lon.attrib["units"] = "degrees_east"
            lon.attrib["long_name"] = "longitude"
            lon[:] = Float32.(lon_in)

            lat = defVar(ncout, "lat", Float32, ("lat",); deflatelevel = 9)
            lat.attrib["units"] = "degrees_north"
            lat.attrib["long_name"] = "latitude"
            lat[:] = Float32.(lat_in)

            lsm = defVar(ncout, "lsm", Float32, ("lon", "lat"); deflatelevel = 9)
            lsm.attrib["units"] = "1"
            lsm.attrib["long_name"] = "ERA5 land fraction"
            lsm.attrib["description"] = "Land fraction from ERA5 reanalysis (0 = ocean, 1 = land)"
            lsm[:] = Float32.(lsm_lonlat)

            # Global attributes
            ncout.attrib["title"] = "ERA5 Land Fraction"
            ncout.attrib["source"] = "ECMWF ERA5 Reanalysis"
            ncout.attrib["history"] = "Created by CliMA (see era5_land_fraction folder in ClimaArtifacts)"
            ncout.attrib["Conventions"] = "CF-1.6"
        end
    end
    @info "Preprocessed ERA5 land fraction saved to $outfile"
end

preprocess_era5_land_fraction(FILE_PATH_RAW, outfile_path)

@info "Data file generated!"
create_artifact_guided(output_dir; artifact_name = basename(@__DIR__))
