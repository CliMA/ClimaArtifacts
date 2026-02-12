using Distributed
addprocs()

using ClimaArtifactsHelper
@everywhere using NCDatasets
@everywhere using Interpolations
@everywhere using ProgressMeter
@everywhere using SharedArrays

# Needed to compute density and total energy
import ClimaParams
import Thermodynamics as TD

params = TD.Parameters.ThermodynamicsParameters(Float32)

const FILE_URL = "https://swift.dkrz.de/v1/dkrz_ab6243f85fe24767bb1508712d1eb504/SAPPHIRE/DYAMOND/ifs_oper_T1279_2016080100.nc"
@everywhere const FILE_PATH = "ifs_oper_T1279_2016080100.nc"

output_dir = "atmos_dyamond_summer_artifact"

if isdir(output_dir)
    @warn "$output_dir already exists. Content will end up in the artifact and may be overwritten."
    @warn "Abort this calculation, unless you know what you are doing."
else
    mkdir(output_dir)
end

if !isfile(FILE_PATH)
    @info "$path not found, downloading it (might take a while)"
    dyamond_file = Downloads.download(FILE_URL)
    Base.mv(dyamond_file, FILE_PATH)
end

artifact_name = "DYAMOND_summer_initial_conditions"

@everywhere begin
    const H_EARTH = 7000.0
    const P0 = 1e5
    const NUM_Z = 137
    Plvl(z) = P0 * exp(-z / H_EARTH)
    Plvl_inv(P) = -H_EARTH * log(P / P0)
end

@everywhere function interpolate_column(ain, PSin, bin, target_z, zin, var)
    # z for this particular column
    @. zin = Plvl_inv(ain + PSin * bin)

    # We need nodes to be monotonically increasing, but pressure
    # goes the other way
    reverse!(zin)

    itp = extrapolate(
        interpolate(
            (zin,),
            reverse(var),
            Gridded(Linear()),
        ),
        Flat(),
    )
    return itp.(target_z)
end


z_min, z_max = 10.0, 80e3
exp_z_min, exp_z_max = Plvl(z_min), Plvl(z_max)
target_z = Plvl_inv.(range(exp_z_min, exp_z_max, NUM_Z))

Base.rm(joinpath(output_dir, "dyamond_atmos_initial_conditions.nc"), force = true)

@everywhere infile_path = FILE_PATH
outfile_path = joinpath(output_dir, "dyamond_atmos_initial_conditions.nc")

@everywhere FT = Float32

@everywhere ncin = NCDataset(infile_path)
global_attrib = copy(ncin.attrib)
curr_history = global_attrib["history"]
new_history =
    curr_history *
    "; Modified by CliMA (see atmos_dyamond_summer in ClimaArtifacts)"
global_attrib["history"] = new_history
ncout = NCDataset(outfile_path, "c")

defDim(ncout, "lon", length(ncin["lon"]))
defDim(ncout, "lat", length(ncin["lat"]))
defDim(ncout, "z", length(target_z))

lon = defVar(ncout, "lon", FT, ("lon",), attrib = ncin["lon"].attrib)
lon[:] = Array(ncin["lon"])

lat = defVar(ncout, "lat", FT, ("lat",), attrib = ncin["lat"].attrib)
lat[:] = Array(ncin["lat"])

z = defVar(ncout, "z", FT, ("z",))
z[:] = Array(target_z)
z.attrib["long_name"] = "altitude"
z.attrib["units"] = "meters"

numlon, numlat = length(lon), length(lat)

function write_var(name, ncin, ncout)
    @info "Reticulating splines for $name"
    defVar(
        ncout,
        name,
        FT,
        ("lon", "lat", "z"),
        attrib = ncin[name].attrib,
    )

    # From CF conventions
    # p(n,k,j,i) = ap(k) + b(k)*ps(n,j,i)

    # From file description
    # mlev=hyam+hybm*aps
    # with ap: hyam b: hybm ps: aps

    @everywhere PSin = exp.(ncin["lnsp"][:, :, 1, 1])
    @everywhere ain = ncin["hyam"][:]
    @everywhere bin = ncin["hybm"][:]

    @everywhere numP = length(ain)
    @everywhere zin = zeros(numP)

    # Save to array, and let only one process write to file
    output_array = SharedArray{Float32}(numlon, numlat, length(target_z))

    @showprogress @distributed for i in 1:numlon
        for j in 1:numlat
            var = ncin[name][i, j, :, 1]
            output_array[i, j, :] .= interpolate_column(ain, PSin[i, j], bin, target_z, zin, var)
        end
    end

    ncout[name][:, :, :] = output_array
end

@showprogress for name in ("v", "u", "cswc", "crwc", "ciwc", "clwc", "q", "t", "w")
    write_var(name, ncin, ncout)
end

close(ncout)
close(ncin)
