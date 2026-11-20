using NCDatasets
using ClimaArtifactsHelper

# Packages the spun-up 1850 state of ClimaLand, written as NetCDF by
# `experiments/trendy_spinup_1850/state_to_netcdf.jl` on the ClimaLand branch named in the
# README (see make_state_netcdf.sh), with the annual CO2 series of that branch.
if length(ARGS) < 2
    @error("Please provide the paths to climaland_1850_spunup_ic.nc and co2_annual_1700_2025.csv.")
else
    nc_path, co2_path = ARGS[1:2]
end
outdir = "climaland_1850_spunup_ic"
if isdir(outdir)
    @warn "$outdir already exists. Content will end up in the artifact and may be overwritten."
    @warn "Abort this calculation, unless you know what you are doing."
else
    mkdir(outdir)
end

required = ("lon", "lat", "z", "land_mask", "soilco2_SOC", "soilco2_O2", "soil_vartheta_l", "canopy_biomass_C_stem")
NCDataset(nc_path) do ds
    for name in required
        haskey(ds, name) || error("$nc_path has no variable $name")
    end
    println(length(keys(ds)), " variables on a ", ds.dim["lon"], " × ", ds.dim["lat"], " × ", ds.dim["z"], " grid")
end
cp(nc_path, joinpath(outdir, "climaland_1850_spunup_ic.nc"); force = true)

# The annual CO2 of the spin-up (1850) and of the transient runs from it
startswith(first(readlines(co2_path)), "year,co2_ppm") ||
    error("$co2_path does not start with the header year,co2_ppm")
cp(co2_path, joinpath(outdir, "co2_annual_1700_2025.csv"); force = true)

create_artifact_guided(outdir; artifact_name = basename(@__DIR__))
