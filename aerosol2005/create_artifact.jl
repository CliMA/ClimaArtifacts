using Dates
using Downloads
using Interpolations
using NCDatasets
using ProgressMeter

using ClimaArtifactsHelper

const FILE_URL = "https://caltech.box.com/shared/static/rr0mg80yhukexcwz8lb99sdt9cut0zlk.nc"
const FILE_PATH = "aero_1.9x2.5_L26_2000-2009.nc"

const H_EARTH = 7000.0
const P0 = 1e5
const NUM_Z = 30

Plvl(z) = P0 * exp(-z / H_EARTH)
Plvl_inv(P) = -H_EARTH * log(P / P0)

function create_aerosol(infile_path, outfile_path, target_z)
    FT = Float64

    ncin = NCDataset(infile_path)
    ncout = NCDataset(outfile_path, "c")

    defDim(ncout, "lon", length(ncin["lon"]))
    defDim(ncout, "lat", length(ncin["lat"]))
    defDim(ncout, "z", length(target_z))
    defDim(ncout, "time", length(ncin["time"]))

    lon = defVar(ncout, "lon", FT, ("lon",), attrib = ncin["lon"].attrib)
    lon[:] = Array(ncin["lon"])

    lat = defVar(ncout, "lat", FT, ("lat",), attrib = ncin["lat"].attrib)
    lat[:] = Array(ncin["lat"])

    z = defVar(ncout, "z", FT, ("z",))
    z[:] = Array(target_z)
    z.attrib["long_name"] = "altitude"
    z.attrib["units"] = "meters"

    time_ = defVar(ncout, "time", FT, ("time",), attrib = ncin["time"].attrib)
    # The NCAR model uses the last day of a monthly average as their output date,
    # so we shift by 15 days
    time_[:] = Array(ncin["time"]) .- Day(15)

    function write_aerosol(name, ncin, ncout, FT)
        @info "Reticulating splines for $name"
        defVar(
            ncout,
            name,
            FT,
            ("lon", "lat", "z", "time"),
            attrib = ncin[name].attrib,
        )

        P0in = ncin["P0"][:][]
        PSin = ncin["PS"][:, :, :]
        ain = ncin["hyam"][:]
        bin = ncin["hybm"][:]

        numP = length(ain)
        numlon, numlat, numtime = size(PSin)
        zin = zeros(numP)

        @showprogress for i in 1:numlon
            for j in 1:numlat
                for k in 1:numtime
                    # z for this particular column at this particular time
                    @. zin = Plvl_inv(PSin[i, j, k] * bin + P0in * ain)

                    # We need nodes to be monotonically increasing, but pressure
                    # goes the other way
                    reverse!(zin)

                    itp = extrapolate(
                        interpolate(
                            (zin,),
                            reverse(ncin[name][i, j, :, k]),
                            Gridded(Linear()),
                        ),
                        Flat(),
                    )

                    ncout[name][i, j, :, k] = itp.(target_z)
                end
            end
        end
    end

    for name in (
        "CB1",
        "CB2",
        "DST01",
        "DST02",
        "DST03",
        "DST04",
        "OC1",
        "OC2",
        "SO4",
        "SOA",
        "SSLT01",
        "SSLT02",
        "SSLT03",
        "SSLT04",
    )
        write_aerosol(name, ncin, ncout, FT)
    end

    close(ncout)
    close(ncin)
end

z_min, z_max = 10.0, 60e3
exp_z_min, exp_z_max = Plvl(z_min), Plvl(z_max)
target_z = Plvl_inv.(range(exp_z_min, exp_z_max, NUM_Z))

output_dir = "aerosol_artifact"

if isdir(output_dir)
    @warn "$output_dir already exists. Content will end up in the artifact and may be overwritten."
    @warn "Abort this calculation, unless you know what you are doing."
else
    mkdir(output_dir)
end

if !isfile(FILE_PATH)
    @info "$FILE_PATH not found, downloading it (might take a while)"
    aerosol_file = Downloads.download(FILE_URL)
    Base.mv(aerosol_file, FILE_PATH)
end

create_aerosol(FILE_PATH, joinpath(output_dir, "aero_2005.nc"), target_z)

@info "Data file generated!"
create_artifact_guided(output_dir; artifact_name = basename(@__DIR__))
