using NCDatasets
using SHA
using ClimaArtifactsHelper

# Packages the initial condition written by `make_ic.jl` from the spin-up described in
# the README. The file is copied byte for byte, so the checksum below identifies it.
const EXPECTED_SHA256 = "c809edd8b7e75043d3374d72bf82d8902e530fc223997cef31d74aa93821ede5"

if length(ARGS) < 1
    @error("Please provide the path to hydro_A_2140-02_ic.nc.")
else
    nc_path = ARGS[1]
end
outdir = "deep_water_table_spunup_ic"
if isdir(outdir)
    @warn "$outdir already exists. Content will end up in the artifact and may be overwritten."
    @warn "Abort this calculation, unless you know what you are doing."
else
    mkdir(outdir)
end

checksum = bytes2hex(open(sha256, nc_path))
checksum == EXPECTED_SHA256 ||
    error("$nc_path has sha256 $checksum, not the documented $EXPECTED_SHA256")

# Same names, dimensions and grid as rosetta_spunup_ic, so the two are interchangeable
NCDataset(nc_path) do ds
    for name in ("lon", "lat", "z", "swc", "si", "sie", "swe", "lwp")
        haskey(ds, name) || error("$nc_path has no variable $name")
    end
    (ds.dim["lon"], ds.dim["lat"], ds.dim["z"]) == (360, 180, 15) ||
        error("$nc_path is not on the 360 × 180 × 15 grid")
    for name in ("swc", "si", "sie", "swe", "lwp")
        all(isfinite, ds[name].var[:]) || error("$name has non-finite values")
    end
end
cp(nc_path, joinpath(outdir, "deep_water_table_spunup_ic.nc"); force = true)

create_artifact_guided(outdir; artifact_name = basename(@__DIR__))
