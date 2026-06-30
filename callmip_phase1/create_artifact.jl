# Creates the `callmip_phase1` artifact from the CalLMIP Phase 1 repository
# (https://github.com/callmip-org/Phase1, MIT license).
#
# The artifact packages the CalLMIP Phase 1 `Data/` tree:
#   - Phase1a-test/  : the DK-Sor single-site test-calibration flux file
#                      (DK-Sor_daily_aggregated_1997-2013_FLUXNET2015_Flux.nc; NEE, Qle, Qh
#                       + uncertainties; site metadata in global attributes)
#   - Phase1b/       : daily-aggregated flux observation files for the 21 Phase 1b sites
#   - Non-site-specific_forcing/ : atmospheric CO2 forcing (TRENDY v2025)
#
# NOTE: the per-site *meteorological forcing* is NOT part of the CalLMIP repository
# (it is the upstream FLUXNET2015 data, obtained separately), so it is not included here.
#
# To recreate: `julia --project create_artifact.jl` (interactive: you will be asked to
# upload the produced tarball and paste its download link).

using Downloads
using ClimaArtifactsHelper

# Pinned to a specific callmip-org/Phase1 commit for reproducibility: building from this
# commit reproduces the git-tree-sha1 in OutputArtifacts.toml
# (c8014d3bbd838fcaa01bd2a69523b3fa98f28c5c). Bump this SHA to repackage a newer release.
const COMMIT = "4101e36679de42789fbd600f4ee69d0cf16b78fc"
const REPO_TARBALL = "https://github.com/callmip-org/Phase1/archive/$(COMMIT).tar.gz"

output_dir = "callmip_phase1_artifact"
if isdir(output_dir)
    @warn "$output_dir already exists. Content will end up in the artifact and may be overwritten."
    @warn "Abort this calculation, unless you know what you are doing."
else
    mkdir(output_dir)
end

# Download + extract the CalLMIP Phase 1 repository tarball, then keep only Data/.
@info "Downloading CalLMIP Phase 1 repository tarball ($COMMIT)"
tgz = Downloads.download(REPO_TARBALL)
extract_dir = mktempdir()
run(`tar -xzf $tgz -C $extract_dir`)
# GitHub tarballs extract to a single top-level folder `Phase1-<commit>`.
repo_root = only(filter(isdir, readdir(extract_dir; join = true)))
data_src = joinpath(repo_root, "Data")
isdir(data_src) || error("Data/ not found in the CalLMIP tarball at $repo_root")

cp(data_src, joinpath(output_dir, "Data"); force = true)
@info "CalLMIP Phase 1 Data/ assembled into $output_dir"

create_artifact_guided(output_dir; artifact_name = basename(@__DIR__))
