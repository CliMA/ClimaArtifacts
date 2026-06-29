# Creates the `callmip_phase1_forcing` artifact: gap-filled in-situ meteorological
# forcing (drivers + LAI) for the 21 CalLMIP Phase 1b calibration sites.
#
# Provenance: per the CalLMIP Phase 1 protocol (v2), the met forcing is downloaded from
# the CalLMIP workspace on modelevaluation.org (ME-org; requires an account). The data
# derive from the PLUMBER2 dataset (Abramowitz et al., 2024), pre-selected FLUXNET2015
# (CC-BY-4.0) sites.
#
# Because ME-org requires authentication, the files cannot be fetched automatically here.
# Obtain the Phase 1b forcing from ME-org and point CALLMIP_MET_SRC at either the
# directory of `*_Met.nc` files or the ME-org `Phase-1b-Calibration-DS.zip`:
#
#   CALLMIP_MET_SRC=/path/to/Phase-1b-Calibration-DS.zip julia --project create_artifact.jl
#
using ClimaArtifactsHelper

src = get(ENV, "CALLMIP_MET_SRC", "")
isempty(src) && error(
    "Set CALLMIP_MET_SRC to the directory of *_Met.nc files or the ME-org " *
    "Phase-1b-Calibration-DS.zip (obtained from modelevaluation.org).",
)

output_dir = "callmip_phase1_forcing_artifact"
if isdir(output_dir)
    @warn "$output_dir already exists. Content will end up in the artifact and may be overwritten."
else
    mkdir(output_dir)
end

if endswith(src, ".zip")
    @info "Extracting *_Met.nc from $src"
    run(`unzip -o -j $src "*_Met.nc" -d $output_dir`)
else
    @info "Copying *_Met.nc from $src"
    for f in readdir(src; join = true)
        endswith(f, "_Met.nc") && cp(f, joinpath(output_dir, basename(f)); force = true)
    end
end

n = count(f -> endswith(f, "_Met.nc"), readdir(output_dir))
n == 21 || @warn "Expected 21 *_Met.nc files for Phase 1b, found $n"
@info "Assembled $n met-forcing files into $output_dir"

create_artifact_guided(output_dir; artifact_name = basename(@__DIR__))
