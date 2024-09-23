using Dates
using Downloads
using Interpolations
using NCDatasets
using ProgressMeter

using ClimaArtifactsHelper

FILE_URLs = [
    "https://caltech.box.com/shared/static/vmhilnrtiudk62v7g7d2p7qhtqf9et90.nc",
    "https://caltech.box.com/shared/static/188kkby2l2zszb7hw5l9dw3ponupzcow.nc",
    "https://caltech.box.com/shared/static/48gtq6w2un9xhdmr1ouhl6mal4grv7mj.nc",
    "https://caltech.box.com/shared/static/rr0mg80yhukexcwz8lb99sdt9cut0zlk.nc",
    "https://caltech.box.com/shared/static/kvbn8osym3vvsnmqafdum4iein0weuvu.nc",
    "https://caltech.box.com/shared/static/qh9jw87webqh3x8z1bs87mv947unwkju.nc",
    "https://caltech.box.com/shared/static/40ojnyjxqbh9m15fo479od8d0kzzm2ic.nc",
]
FILE_PATHs = [
    "aero_1.9x2.5_L26_1970-1979.nc",
    "aero_1.9x2.5_L26_1980-1989.nc",
    "aero_1.9x2.5_L26_1990-1999.nc",
    "aero_1.9x2.5_L26_2000-2009.nc",
    "aero_1.9x2.5_L26_2010-2019.nc",
    "aero_1.9x2.5_L26_2020-2029.nc",
    "aero_1.9x2.5_L26_2030-2039.nc",
]

const H_EARTH = 7000.0
const P0 = 1e5
const NUM_Z = 42

Plvl(z) = P0 * exp(-z / H_EARTH)
Plvl_inv(P) = -H_EARTH * log(P / P0)

function create_aerosol(infile_paths, outfile_path, target_z; small = false)
    THINNING_FACTOR = 1
    FT = Float32

    aerosol_names = (
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

    if small
        THINNING_FACTOR = 6
        FT = Float32
        target_z = target_z[begin:THINNING_FACTOR:end]
        aerosol_names = ("SO4", "SSLT01", "CB1")
        infile_paths = (first(infile_paths),) # Keep only one year
    end

    ncin = NCDataset(first(infile_paths))
    ncout = NCDataset(outfile_path, "c")

    defDim(ncout, "lon", Int(ceil(length(ncin["lon"]) // THINNING_FACTOR)))
    defDim(ncout, "lat", Int(ceil(length(ncin["lat"]) // THINNING_FACTOR)))
    defDim(ncout, "z", length(target_z))
    # We assume that each file contains the same amount of dates, the 12 months
    num_times = length(ncin["time"])
    defDim(ncout, "time", num_times * length(infile_paths))

    lon = defVar(ncout, "lon", FT, ("lon",), attrib = ncin["lon"].attrib)
    lon[:] = Array(ncin["lon"])[begin:THINNING_FACTOR:end]

    lat = defVar(ncout, "lat", FT, ("lat",), attrib = ncin["lat"].attrib)
    lat[:] = Array(ncin["lat"])[begin:THINNING_FACTOR:end]

    z = defVar(ncout, "z", FT, ("z",))
    z[:] = Array(target_z)
    z.attrib["long_name"] = "altitude"
    z.attrib["units"] = "meters"

    numlon, numlat, numtime = length(lon), length(lat), num_times

    time_ = defVar(ncout, "time", FT, ("time",), attrib = ncin["time"].attrib)
    close(ncin)

    function write_aerosol(name, ncin, ncout, FT; first_time_index = 1)
        # The NCAR model uses the last day of a monthly average as their output date,
        # so we shift by 15 days
        num_times = length(ncin["time"])
        time_[first_time_index:(first_time_index + num_times - 1)] =
            Array(ncin["time"]) .- Day(15)

        @info "Reticulating splines for $name at time index $first_time_index"
        if !haskey(ncout, name)
            defVar(
                ncout,
                name,
                FT,
                ("lon", "lat", "z", "time"),
                attrib = ncin[name].attrib,
            )
        end

        P0in = ncin["P0"][:][]
        PSin = ncin["PS"][:, :, :]
        ain = ncin["hyam"][:]
        bin = ncin["hybm"][:]

        numP = length(ain)
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

                    ncout[name][i, j, :, first_time_index + k - 1] =
                        itp.(target_z)
                end
            end
        end
    end

    for name in aerosol_names
        @showprogress for (index, file) in enumerate(infile_paths)
            first_time_index = 1 + num_times * (index - 1)
            ncin = NCDataset(file)
            write_aerosol(name, ncin, ncout, FT; first_time_index)
        end
    end

    close(ncout)
end

z_min, z_max = 10.0, 80e3
exp_z_min, exp_z_max = Plvl(z_min), Plvl(z_max)
target_z = Plvl_inv.(range(exp_z_min, exp_z_max, NUM_Z))

output_dir = "aerosol_artifact"

if isdir(output_dir)
    @warn "$output_dir already exists. Content will end up in the artifact and may be overwritten."
    @warn "Abort this calculation, unless you know what you are doing."
else
    mkdir(output_dir)
end

foreach(zip(FILE_PATHs, FILE_URLs)) do (path, url)
    if !isfile(path)
        @info "$path not found, downloading it (might take a while)"
        aerosol_file = Downloads.download(url)
        Base.mv(aerosol_file, path)
    end
end

create_aerosol(FILE_PATHs, joinpath(output_dir, "aerosol_concentrations.nc"), target_z)

@info "Data file generated!"
create_artifact_guided(output_dir; artifact_name = basename(@__DIR__))

output_dir_lowres = "aerosol_artifact_lowres"

if isdir(output_dir_lowres)
    @warn "$output_dir already exists. Content will end up in the artifact and may be overwritten."
    @warn "Abort this calculation, unless you know what you are doing."
else
    mkdir(output_dir_lowres)
end

foreach(zip(FILE_PATHs, FILE_URLs)) do (path, url)
    if !isfile(path)
        @info "$path not found, downloading it (might take a while)"
        aerosol_file = Downloads.download(url)
        Base.mv(aerosol_file, path)
    end
end

create_aerosol(
    FILE_PATHs,
    joinpath(output_dir_lowres, "aerosol_concentrations_lowres.nc"),
    target_z;
    small = true,
)

create_artifact_guided(
    output_dir_lowres;
    artifact_name = basename(@__DIR__) * "_lowres",
)
