#!/usr/bin/env bash
# Run from the saturated_land_ic directory
set -euo pipefail

CLIMALAND_DIR="${1:-ClimaLand.jl}"
OUTPUT_DIR="${2:-climaland_output}"

[ ! -d "${CLIMALAND_DIR}" ] && git clone https://github.com/CliMA/ClimaLand.jl.git "${CLIMALAND_DIR}"

cd "${CLIMALAND_DIR}"
git -c advice.detachedHEAD=false checkout 9be57aff5200d832c5d90abeb157754ab202921b
export LONGER_RUN=true
julia --project=experiments experiments/long_runs/snowy_land_pmodel.jl

cd -
julia --project=. create_artifacts.jl "${OUTPUT_DIR}"
