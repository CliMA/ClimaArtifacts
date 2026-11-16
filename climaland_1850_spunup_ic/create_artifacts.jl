using NCDatasets
using ClimaArtifactsHelper

# Packages the spun-up 1850 state of ClimaLand, written as NetCDF by
# `experiments/trendy_spinup_1850/state_to_netcdf.jl` on the ClimaLand branch named in the
# README (see make_state_netcdf.sh).
if length(ARGS) < 1
    @error("Please provide the path to climaland_1850_spunup_ic.nc.")
else
    nc_path = ARGS[1]
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

create_artifact_guided(outdir; artifact_name = basename(@__DIR__))
