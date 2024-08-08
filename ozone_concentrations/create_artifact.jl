using Dates
using Downloads
using Interpolations
using NCDatasets
using ProgressMeter

using ClimaArtifactsHelper

FILE_URLs = [
    "https://caltech.box.com/shared/static/h3c8rlpctxpq3uh1r01zhips426lgi0e.nc",
             ]
FILE_PATHs = ["vmro3_input4MIPs_ozone_CMIP_UReading-CCMI-1-0_gn_200001-201412.nc",
              ]

const H_EARTH = 7000.0
const P0 = 1e5
const NUM_Z = 30
const HPA_TO_PA = 100.0

Plvl(z) = P0 * exp(-z / H_EARTH)
Plvl_inv(P) = -H_EARTH * log(P / P0)

function create_ozone(infile_paths, outfile_path, target_z)
    FT = Float64

    ncin = NCDataset(first(infile_paths))
    ncout = NCDataset(outfile_path, "c")

    defDim(ncout, "lon", length(ncin["lon"]))
    defDim(ncout, "lat", length(ncin["lat"]))
    defDim(ncout, "z", length(target_z))
    # We assume that each file contains the same amount of dates, the 12 months
    num_times = length(ncin["time"])
    num_times = 2
    defDim(ncout, "time", num_times)

    lon = defVar(ncout, "lon", FT, ("lon",), attrib = ncin["lon"].attrib)
    lon[:] = Array(ncin["lon"])

    lat = defVar(ncout, "lat", FT, ("lat",), attrib = ncin["lat"].attrib)
    lat[:] = Array(ncin["lat"])

    z = defVar(ncout, "z", FT, ("z",))
    z[:] = Array(target_z)
    z.attrib["long_name"] = "altitude"
    z.attrib["units"] = "meters"

    time_ = defVar(ncout, "time", FT, ("time",), attrib = ncin["time"].attrib)
    close(ncin)

    function write_ozone(name, ncin, ncout, FT; first_time_index = 1)
        # The NCAR model uses the last day of a monthly average as their output date,
        # so we shift by 15 days
        num_times = length(ncin["time"])
        time_[:] = Array(ncin["time"])[1:2]

        @info "Reticulating splines for $name at time index $first_time_index"
        if !haskey(ncout, name)
            defVar(
                ncout,
                name,
                FT,
                ("lon", "lat", "z", "time"),
                attrib = filter(((k, v),) -> k != "_FillValue", ncin["vmro3"].attrib),
            )
        end

        plevin = ncin["plev"][:] .* HPA_TO_PA

        numP = length(plevin)
        numlon, numlat, numP, numtime = size(ncin[name])
        numtime = 2
        zin = zeros(numP)

        @showprogress for i in 1:numlon
            for j in 1:numlat
                for k in 1:numtime
                    # z for this particular column at this particular time
                    @. zin = Plvl_inv(plevin)

                    # We need nodes to be monotonically increasing, but pressure
                    # goes the other way
                    # reverse!(zin)

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

    @showprogress for (index, file) in enumerate(infile_paths)
        first_time_index = 1 + num_times * (index - 1)
        ncin = NCDataset(file)
        write_ozone("vmro3", ncin, ncout, FT; first_time_index)
    end

    close(ncout)
end

z_min, z_max = 10.0, 60e3
exp_z_min, exp_z_max = Plvl(z_min), Plvl(z_max)
target_z = Plvl_inv.(range(exp_z_min, exp_z_max, NUM_Z))

output_dir = "ozone_artifact"

if isdir(output_dir)
    @warn "$output_dir already exists. Content will end up in the artifact and may be overwritten."
    @warn "Abort this calculation, unless you know what you are doing."
else
    mkdir(output_dir)
end

foreach(zip(FILE_PATHs, FILE_URLs)) do (path, url)
    if !isfile(path)
    @info "$path not found, downloading it (might take a while)"
        ozone_file = Downloads.download(url)
        Base.mv(ozone_file, path)
    end
end

create_ozone(FILE_PATHs, joinpath(output_dir, "ozone_concentrations.nc"), target_z)

@info "Data file generated!"
create_artifact_guided(output_dir; artifact_name = basename(@__DIR__))
