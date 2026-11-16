#!/usr/bin/env bash
# Run from the climaland_1850_spunup_ic directory:
#
#   bash make_state_netcdf.sh <spun_1909.hdf5> [<ClimaLand.jl checkout>]
#
# Writes climaland_1850_spunup_ic.nc from the spun-up state (every field of the model
# state, checked by reading it back), the figure soc_spinup_1850_vs_soilgrids.png and its
# table, then packages the artifact. The state comes from the spin-up described in
# ClimaLand.jl/experiments/trendy_spinup_1850/README.md at the commit below.
set -euo pipefail

STATE="${1:?give the path of the spun-up state, spun_1909.hdf5}"
CLIMALAND_DIR="${2:-ClimaLand.jl}"
COMMIT=772d7135ff3db34a822fcbdb56f35bbdda307d24

[ ! -d "${CLIMALAND_DIR}" ] && git clone https://github.com/CliMA/ClimaLand.jl.git "${CLIMALAND_DIR}"
git -C "${CLIMALAND_DIR}" fetch origin ar/trendy_spinup_1850
git -C "${CLIMALAND_DIR}" -c advice.detachedHEAD=false checkout "${COMMIT}"
julia --project="${CLIMALAND_DIR}/.buildkite" -e 'using Pkg; Pkg.instantiate()'

SCRIPTS="${CLIMALAND_DIR}/experiments/trendy_spinup_1850"
julia --project="${CLIMALAND_DIR}/.buildkite" "${SCRIPTS}/state_to_netcdf.jl" "${STATE}" \
    climaland_1850_spunup_ic.nc ClimaLand spun-up state at 1850 CO2 with CRU-JRA 1901-1920 recycled
julia --project="${CLIMALAND_DIR}/.buildkite" "${SCRIPTS}/soc_spinup_figure.jl" \
    climaland_1850_spunup_ic.nc . end of spin-up cycle C5 at 1850 CO2 with CRU-JRA 1901-1920 recycled

julia --project=. -e 'using Pkg; Pkg.instantiate()'
julia --project=. create_artifacts.jl climaland_1850_spunup_ic.nc "${SCRIPTS}/co2_annual_1700_2025.csv"
