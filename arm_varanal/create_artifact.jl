using ClimaArtifactsHelper
using Dates

include("subset_obs.jl")

# Path to raw ARM data
# ARM data cannot be downloaded programmatically: it requires a free ARM account
# and a manual data order through ARM Data Discovery (see README). The user must
# place the ordered products under RAW_DATA_DIR/<site>/ before running this script.
# Defaults to a local directory next to this script; override with ARM_RAW_DATA_DIR.
# Raw data is organized by site: arm_varanal_raw/sgp/, arm_varanal_raw/<other_site>/, ...
const RAW_DATA_DIR =
    get(ENV, "ARM_RAW_DATA_DIR", joinpath(@__DIR__, "arm_varanal_raw"))
const SITE = "sgp"
const SITE_DIR = joinpath(RAW_DATA_DIR, SITE)

isdir(SITE_DIR) || error(
    "Raw ARM data not found at $SITE_DIR.\n" *
    "Order the data from ARM Data Discovery (see README) and place the product " *
    "directories under $SITE_DIR, or set ARM_RAW_DATA_DIR to where they live.",
)

const FORCING_FILE = "sgp60varanarucC1.c1.20100901.000000.cdf"

# Subset window for the downloadable obs artifact (must cover CI simulation window).
# CI runs prognostic_edmfx_armvaranal_column: start_date 20100918, t_end 4days → Sept 18–22.
# Each sonde file is ~61 MB, so keep the window small enough to stay under 500 MB.
const SUBSET_START = Date(2010, 9, 18)
const SUBSET_END = Date(2010, 9, 22)

const FORCING_ARTIFACT = "arm_sgp_varanal_forcing"
const OBS_ARTIFACT = "arm_sgp_varanal_obs"
const OBS_FULL_ARTIFACT = "arm_sgp_varanal_obs_full"

# ============================================================================
# Stage forcing artifact: arm_sgp_varanal_forcing
# ============================================================================

forcing_dir = FORCING_ARTIFACT * "_artifact"
if isdir(forcing_dir)
    @warn "$forcing_dir already exists. Content will end up in the artifact and may be overwritten."
    @warn "Abort this calculation, unless you know what you are doing."
else
    mkdir(forcing_dir)
end

forcing_src = joinpath(SITE_DIR, "sgp60varanarucC1.c1", FORCING_FILE)
isfile(forcing_src) ||
    error("Forcing file not found at $forcing_src. Order it from ARM (see README).")
cp(forcing_src, joinpath(forcing_dir, FORCING_FILE); force = true)

@info "Forcing artifact staged in $forcing_dir"
create_artifact_guided(forcing_dir; artifact_name = FORCING_ARTIFACT)

# ============================================================================
# Stage subsetted obs artifact: arm_sgp_varanal_obs (downloadable, for CI)
# Layout mirrors the raw ARM product directory names so that obs and obs_full
# artifacts have the same structure, and obs_full == raw (no duplication).
# ============================================================================

obs_dir = OBS_ARTIFACT * "_artifact"
if isdir(obs_dir)
    @warn "$obs_dir already exists. Content will end up in the artifact and may be overwritten."
    @warn "Abort this calculation, unless you know what you are doing."
else
    mkdir(obs_dir)
end

sonde_src = joinpath(SITE_DIR, "sgpinterpolatedsondeC1.c1")
sonde_dst = joinpath(obs_dir, "sgpinterpolatedsondeC1.c1")
mkdir(sonde_dst)
copy_daily_files(sonde_src, sonde_dst, SUBSET_START, SUBSET_END)

beatm_src = joinpath(SITE_DIR, "sgparmbeatmC1.c1", "sgparmbeatmC1.c1.20100101.000000.cdf")
beatm_dst = joinpath(obs_dir, "sgparmbeatmC1.c1")
mkdir(beatm_dst)
subset_nc_by_time(
    beatm_src,
    joinpath(beatm_dst, "sgparmbeatmC1.c1.201009.cdf"),
    SUBSET_START,
    SUBSET_END,
)

cldrad_src = joinpath(SITE_DIR, "sgparmbecldradC1.c1", "sgparmbecldradC1.c1.20100101.000000.cdf")
cldrad_dst = joinpath(obs_dir, "sgparmbecldradC1.c1")
mkdir(cldrad_dst)
subset_nc_by_time(
    cldrad_src,
    joinpath(cldrad_dst, "sgparmbecldradC1.c1.201009.cdf"),
    SUBSET_START,
    SUBSET_END,
)

@info "Subsetted obs artifact staged in $obs_dir ($(round(ClimaArtifactsHelper.foldersize(obs_dir) / 1e6; digits = 1)) MB)"
create_artifact_guided(obs_dir; artifact_name = OBS_ARTIFACT, append = true)

# ============================================================================
# Full obs artifact: arm_sgp_varanal_obs_full (too large to download, ~42 GB)
#
# This artifact *is* the raw site directory (same product-name layout as the obs
# subset), so the script does not stage a separate copy. create_artifact_guided
# computes the hash from SITE_DIR and prints the Overrides.toml entry; that entry
# should point directly at SITE_DIR on the cluster.
# ============================================================================

@info "Full obs artifact is the raw data at $SITE_DIR ($(round(ClimaArtifactsHelper.foldersize(SITE_DIR) / 1e9; digits = 2)) GB)"
create_artifact_guided(SITE_DIR; artifact_name = OBS_FULL_ARTIFACT, append = true)
