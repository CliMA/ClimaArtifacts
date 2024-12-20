using Downloads
using ClimaArtifactsHelper
using NCDatasets
import ImageMorphology
import OrderedCollections: OrderedDict
import StatsBase: countmap

const FILE_URL_30ARCSEC = "https://www.ngdc.noaa.gov/thredds/fileServer/global/ETOPO2022/30s/30s_surface_elev_netcdf/ETOPO_2022_v1_30s_N90W180_surface.nc"
const FILE_PATH_30ARCSEC = "ETOPO_2022_v1_30s_N90W180_surface.nc"

output_dir_30arcsec = "landsea_mask_30arcsec" * "_artifact"
output_dir_60arcsec = "landsea_mask_60arcsec" * "_artifact"
output_dir_1deg = "landsea_mask_1deg" * "_artifact"

const SEA_LEVEL = 0 # meters

outdirs = (output_dir_30arcsec, output_dir_60arcsec, output_dir_1deg)
for outdir in outdirs
    if isdir(outdir)
        @warn "$outdir already exists. Content will end up in the artifact and may be overwritten."
        @warn "Abort this calculation, unless you know what you are doing."
    else
        mkdir(outdir)
    end
end

if !isfile(FILE_PATH_30ARCSEC)
    @info "$FILE_PATH_30ARCSEC not found, downloading it (might take a while)"
    downloaded_file = Downloads.download(FILE_URL_30ARCSEC; progress = download_rate_callback())
    Base.mv(downloaded_file, FILE_PATH_30ARCSEC)
end


"""
    remove_major_basins(z_data; mark_as_land_fraction = 0.5, sea_level = 0)

Remove independent basins from the topography data stored in `z_data` by
identifying connected regions below sea level (ie, fill the lakes). Basins with
fractional size smaller than `mark_as_land_fraction` are marked as land.

The fractional size is computed by counting the number of cells on the grid with
respect to the total number of cells (as read from the NetCDF file).

The ocean is 65 % of the surface area of the globe.
"""
function remove_major_basins(
    topography;
    mark_as_land_fraction = 0.5,
    sea_level = 0,
)
    nlat, nlon = size(topography)

    # First, we need to pad the topography longitudinally (because
    # ImageMorphology.strel does not understand periodicity). We pad by copying
    # part of the domain left and right (let's do half)
    half_nlat = div(nlat, 2)
    padded_topo = zeros(2nlat, nlon)

    padded_topo[1:half_nlat, :] = topography[(half_nlat + 1):end, :]
    padded_topo[(half_nlat + 1):(half_nlat + nlat), :] = topography
    padded_topo[(half_nlat + nlat + 1):end, :] = topography[begin:half_nlat, :]

    water = padded_topo .< sea_level

    labels = ImageMorphology.label_components(ImageMorphology.strel(water))

    # connectivity_counts maps label to size (measured as number of cells)
    connectivity_counts = countmap(labels)
    component_counts_from_largest =
        sort(collect(values(connectivity_counts)), rev = true)
    total_number_of_cells = sum(values(component_counts_from_largest))
    labels_to_mark_as_water = Set(
        l for (l, c) in connectivity_counts if
        c / total_number_of_cells > mark_as_land_fraction
    )
    @info "Marking $(length(labels_to_mark_as_water)) basins as water (everything else is land)"
    labels = map(Float64, labels)

    # Mark all the basins we found as water
    land = ones(Int8, size(padded_topo)...)
    indices_in_water = map(l -> l in labels_to_mark_as_water, labels)
    land[indices_in_water] .= 0

    return land[(half_nlat + 1):(half_nlat + nlat), :]
end

outfile_path_30arcsecs = joinpath(output_dir_30arcsec, "landsea_mask.nc")
outfile_path_60arcsecs = joinpath(output_dir_60arcsec, "landsea_mask.nc")
outfile_path_1deg = joinpath(output_dir_1deg, "landsea_mask.nc")

function save_ncfile(ncin, landsea_array, outfile_path; THINNING_FACTOR = 1)
    global_attrib = OrderedDict(ncin.attrib)
    global_attrib["description"] = "0 for ocean, 1 for land"
    global_attrib["history"] = "Created by CliMA (see landsea_mask folder in ClimaArtifacts)"
    NCDataset(outfile_path, "c", attrib = global_attrib) do ncout
        defDim(ncout, "lon", Int(ceil(length(ncin["lon"]) // THINNING_FACTOR)))
        defDim(ncout, "lat", Int(ceil(length(ncin["lat"]) // THINNING_FACTOR)))

        lon_attribs = Dict(ncin["lon"].attrib)
        lon = defVar(
            ncout,
            "lon",
            Float32,
            ("lon",),
            attrib = lon_attribs,
            deflatelevel = 9
        )
        lon[:] = Array(ncin["lon"])[begin:THINNING_FACTOR:end]

        lat_attribs = Dict(ncin["lat"].attrib)
        lat = defVar(
            ncout,
            "lat",
            Float32,
            ("lat",),
            attrib = lat_attribs,
            deflatelevel = 9
        )
        lat[:] = Array(ncin["lat"])[begin:THINNING_FACTOR:end]

        landsea =
            defVar(ncout, "landsea", Int8, ("lon", "lat"), deflatelevel = 9)
        landsea[:] = landsea_array[begin:THINNING_FACTOR:end, begin:THINNING_FACTOR:end]
    end
end

NCDataset(FILE_PATH_30ARCSEC) do ncin
    landsea_array = remove_major_basins(Array(ncin["z"]), sea_level = SEA_LEVEL)
    save_ncfile(ncin, landsea_array, outfile_path_30arcsecs; THINNING_FACTOR = 1)
    save_ncfile(ncin, landsea_array, outfile_path_60arcsecs; THINNING_FACTOR = 2)
    save_ncfile(ncin, landsea_array, outfile_path_1deg; THINNING_FACTOR = 120)
end

create_artifact_guided(
    output_dir_30arcsec;
    artifact_name = basename(@__DIR__) * "_30arcseconds",
)
create_artifact_guided(
    output_dir_60arcsec;
    artifact_name = basename(@__DIR__) * "_60arcseconds",
    append = true,
)
create_artifact_guided(
    output_dir_1deg;
    artifact_name = basename(@__DIR__) * "_1deg",
    append = true,
)

@info "Generated land sea mask file"
