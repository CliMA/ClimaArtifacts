# Creates the `xusaatchi_woody_carbon` artifact for ClimaLand: the 2000-2019 mean carbon
# of the live woody vegetation, above and below ground, of Xu et al. (2021), as
# distributed by ILAMB at 0.5°, averaged in 1° blocks, in kg C m^-2, NaN over ocean.
#
#     julia --project create_artifact.jl

using Downloads
using NCDatasets
using SHA
using Statistics
using ClimaArtifactsHelper

const URL = "https://www.ilamb.org/ILAMB-Data/DATA/biomass/XuSaatchi2021/XuSaatchi.nc"
const SHA256 = "ab93cb57ee2a9e35fb0fff2e64da2f03a6a83358ef9936f52e51f929f143cc36"
const BLOCK = 2 # 0.5° cells per 1° block
const OUTPUT_DIR = joinpath(@__DIR__, "xusaatchi_woody_carbon_artifact")

source = Downloads.download(URL; progress = download_rate_callback())
@assert bytes2hex(open(SHA.sha256, source)) == SHA256 "$source does not match $URL"

lon, lat, biomass = NCDataset(source) do ds
    Array(ds["lon"][:]), Array(ds["lat"][:]), ds["biomass"].var[:, :, :]
end
# Mg C ha^-1 to kg C m^-2, averaged over the years
valid(x) = isfinite(x) && x >= 0
time_mean = map(CartesianIndices(size(biomass)[1:2])) do I
    x = filter(valid, 0.1 .* biomass[I, :])
    isempty(x) ? NaN : mean(x)
end
# Longitudes in [-180, 180) and latitudes ascending
lon = @. ifelse(lon >= 180, lon - 360, lon)
lon_order, lat_order = sortperm(lon), sortperm(lat)
lon, lat = lon[lon_order], lat[lat_order]
time_mean = time_mean[lon_order, lat_order]

# A block is land where at least half of its cells are
function block_mean(x)
    v = filter(isfinite, x)
    return 2 * length(v) >= length(x) ? mean(v) : NaN
end
nlon, nlat = length(lon) ÷ BLOCK, length(lat) ÷ BLOCK
blocks(i) = ((i - 1) * BLOCK + 1):(i * BLOCK)
woody_carbon =
    [block_mean(time_mean[blocks(i), blocks(j)]) for i in 1:nlon, j in 1:nlat]
block_lon = [round(mean(lon[blocks(i)]); digits = 6) for i in 1:nlon]
block_lat = [round(mean(lat[blocks(j)]); digits = 6) for j in 1:nlat]

isdir(OUTPUT_DIR) || mkdir(OUTPUT_DIR)
NCDataset(joinpath(OUTPUT_DIR, "xusaatchi_woody_carbon_1deg.nc"), "c") do out
    out.attrib["title"] = "Live woody carbon, above and below ground, 2000-2019 mean, 1 degree blocks"
    out.attrib["source"] = URL
    out.attrib["references"] = "Xu et al. (2021), https://doi.org/10.1126/sciadv.abe9829"
    defVar(out, "lon", block_lon, ("lon",); attrib = ["units" => "degrees_east"])
    defVar(out, "lat", block_lat, ("lat",); attrib = ["units" => "degrees_north"])
    defVar(
        out,
        "woody_carbon",
        Float32.(woody_carbon),
        ("lon", "lat");
        deflatelevel = 9,
        attrib = [
            "units" => "kg m-2",
            "long_name" => "Carbon in live woody vegetation",
        ],
    )
end

create_artifact_guided(OUTPUT_DIR; artifact_name = basename(@__DIR__))
