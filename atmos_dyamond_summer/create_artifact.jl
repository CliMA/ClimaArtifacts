using ClimaArtifactsHelper

const FILE_URL = "https://swift.dkrz.de/v1/dkrz_ab6243f85fe24767bb1508712d1eb504/SAPPHIRE/DYAMOND/ifs_oper_T1279_2016080100.nc"
const FILE_PATH = "ifs_oper_T1279_2016080100.nc"

artifact_name = "DYAMOND_summer_initial_conditions"

const NUM_Z = 42

function create_artifact(infile_path, outfile_path, target_z)
    ncin = NCDataset(infile_path)
    ncout = NCDataset(outfile_path, "c")

    defDim(ncout, "lon", length(ncin["lon"])
    defDim(ncout, "lat", length(ncin["lat"])
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

    function write_var(name, ncin, ncout, FT; first_time_index = 1)
        @info "Reticulating splines for $name at time index $first_time_index"
           defVar(
               ncout,
               name,
               FT,
               ("lon", "lat", "z"),
               attrib = ncin[name].attrib,
           )

        P0in = ncin["P0"][:][]
        PSin = ncin["PS"][:, :, :]
        ain = ncin["hyam"][:]
        bin = ncin["hybm"][:]

        numP = length(ain)
        zin = zeros(numP)

        @showprogress for i in 1:numlon
            for j in 1:numlat
                # z for this particular column
                @. zin = Plvl_inv(PSin[i, j] * bin + P0in * ain)

                # We need nodes to be monotonically increasing, but pressure
                # goes the other way
                reverse!(zin)

                itp = extrapolate(
                    interpolate(
                        (zin,),
                        reverse(ncin[name][i, j, :]),
                        Gridded(Linear()),
                    ),
                    Flat(),
                )

                ncout[name][i, j, :] =
                    itp.(target_z)
            end
           end
    end

           @showprogress for name
               write_aerosol(name, ncin, ncout, FT)
           end

    close(ncout)
end

z_min, z_max = 10.0, 80e3
exp_z_min, exp_z_max = Plvl(z_min), Plvl(z_max)
target_z = Plvl_inv.(range(exp_z_min, exp_z_max, NUM_Z))
