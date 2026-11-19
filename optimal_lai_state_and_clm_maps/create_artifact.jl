# Creates the `optimal_lai_state_and_clm_maps` artifact for ClimaLand:
# - `clm_tree_share.nc`: the tree share of the natural vegetation in the CLM5 surface
#   data for the year 2000 (0.9°×1.25°), NaN where there is no vegetation;
# - `clm_crop_fraction.nc`: the fraction of the land in the crop land unit of the same
#   surface data, NaN over ocean;
# - `optimal_lai_state.nc`: the states of ZhouOptimalLAIModel on the first day of each
#   month of 2008 (1°×1°), NaN over ocean, written by a spin-up on Buildkite.
#
#     julia --project create_artifact.jl
#
# The surface data and the spin-up state are downloaded, unless the environment
# variables `CLM_SURFDATA` and `OPTIMAL_LAI_STATE` give local copies.

using Downloads
using NCDatasets
using SHA
using ClimaArtifactsHelper

const SURFDATA_URL = "https://svn-ccsm-inputdata.cgd.ucar.edu/trunk/inputdata/lnd/clm2/surfdata_map/surfdata_0.9x1.25_16pfts__CMIP6_simyr2000_c170616.nc"
const SURFDATA_SHA256 = "b1062bac7a907e5841ec4217cc29a9159758c40c385a4248125a958caa1891c8"
# `optimal_lai_spinup_gpu/optimal_lai_state.nc` of the Optimal LAI spin-up of build 5127
# of climaland-long-runs (ClimaLand.jl commit de43e9d7e), kept by Buildkite until
# April 2027
const STATE_URL = "https://buildkite.com/organizations/clima/pipelines/climaland-long-runs/builds/5127/jobs/01a15ffe-867b-42b1-b241-74d08cd2b4bd/artifacts/01a16091-0242-4e9a-b57d-0723edd6311f"
const STATE_SHA256 = "8d1cd0ebf2e32070c910086abcc4908200e1f95c2675670de5b870e9b8470b47"
# Indices into the natpft dimension (0-14) of PCT_NAT_PFT
const TREE_PFTS = 2:9
const VEGETATED_PFTS = 2:15

const OUTPUT_DIR = joinpath(@__DIR__, "optimal_lai_state_and_clm_maps_artifact")

function local_or_download(env_name, url, sha256)
    path = get(ENV, env_name) do
        Downloads.download(url; progress = download_rate_callback())
    end
    @assert bytes2hex(open(SHA.sha256, path)) == sha256 "$path does not match $url"
    return path
end

function write_map(path, title, lon, lat, name, data, long_name)
    NCDataset(path, "c") do out
        out.attrib["title"] = title
        out.attrib["source"] = SURFDATA_URL
        defVar(out, "lon", lon, ("lon",); attrib = ["units" => "degrees_east"])
        defVar(out, "lat", lat, ("lat",); attrib = ["units" => "degrees_north"])
        defVar(
            out,
            name,
            Float32.(data),
            ("lon", "lat");
            deflatelevel = 9,
            attrib = ["units" => "fraction", "long_name" => long_name],
        )
    end
end

isdir(OUTPUT_DIR) && error("$OUTPUT_DIR exists; remove it to recreate the artifact")
mkpath(OUTPUT_DIR)

surfdata = local_or_download("CLM_SURFDATA", SURFDATA_URL, SURFDATA_SHA256)
ds = NCDataset(surfdata)
lon = Array(ds["LONGXY"][:, 1])
lat = Array(ds["LATIXY"][1, :])
pct_nat_pft = Array(ds["PCT_NAT_PFT"][:, :, :])
pct_crop = Array(ds["PCT_CROP"][:, :])
land_fraction = Array(ds["LANDFRAC_PFT"][:, :])
close(ds)

trees = dropdims(sum(pct_nat_pft[:, :, TREE_PFTS]; dims = 3); dims = 3)
vegetated = dropdims(sum(pct_nat_pft[:, :, VEGETATED_PFTS]; dims = 3); dims = 3)
tree_share = @. ifelse(vegetated > 0, trees / vegetated, NaN)
write_map(
    joinpath(OUTPUT_DIR, "clm_tree_share.nc"),
    "Tree share of the natural vegetation, CLM5 surface data, year 2000",
    lon,
    lat,
    "tree_share",
    tree_share,
    "Tree share of the vegetated natural cover",
)

crop_fraction = @. ifelse(land_fraction > 0, pct_crop / 100, NaN)
write_map(
    joinpath(OUTPUT_DIR, "clm_crop_fraction.nc"),
    "Crop fraction of the land, CLM5 surface data, year 2000",
    lon,
    lat,
    "crop_fraction",
    crop_fraction,
    "Fraction of the land in the crop land unit",
)

state = local_or_download("OPTIMAL_LAI_STATE", STATE_URL, STATE_SHA256)
state_path = joinpath(OUTPUT_DIR, "optimal_lai_state.nc")
cp(state, state_path)
chmod(state_path, 0o644)
# The spin-up wrote 0 rather than NaN over part of the ocean in some months. The land
# cells, the active nodes of the model domain, are those finite in every month.
NCDataset(state_path, "a") do ds
    names = setdiff(keys(ds), ["lon", "lat", "time"])
    land = trues(ds.dim["lon"], ds.dim["lat"])
    for name in names
        land .&= dropdims(all(isfinite, ds[name].var[:, :, :]; dims = 3); dims = 3)
    end
    for name in names
        data = ds[name].var[:, :, :]
        data[.!land, :] .= NaN
        ds[name].var[:, :, :] = data
    end
end

create_artifact_guided(OUTPUT_DIR; artifact_name = basename(@__DIR__))
