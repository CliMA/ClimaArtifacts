using ClimaArtifactsHelper
import ClimaInterpolations.Interpolation1D: interpolate1d!, Linear, Flat
using NCDatasets
using DataStructures
using ClimaParams
import Thermodynamics as TD


const FILE_URL = "https://swift.dkrz.de/v1/dkrz_ab6243f85fe24767bb1508712d1eb504/SAPPHIRE/DYAMOND/ifs_oper_T1279_2016080100.nc"
const FILE_PATH = "ifs_oper_T1279_2016080100.nc"

artifact_name = "DYAMOND_summer_initial_conditions"
create_artifact_guided_one_file(FILE_PATH; artifact_name = artifact_name, file_url = FILE_URL)

const FT = Float32
const H_EARTH = FT(7000.0)
const P0 = FT(1e5)
const z_min, z_max = FT(0), FT(80E3)

const params = TD.Parameters.ThermodynamicsParameters(FT)
const grav = params.grav

include("helper.jl")

Plvl(z) = P0 * exp(-z / H_EARTH)
Plvl_inv(P) = -H_EARTH * log(P / P0)

function create_initial_conditions(infile, outfile; skip = 1)
    ncin = NCDataset(infile, "r")
    ncout = NCDataset(outfile, "c", attrib = copy(ncin.attrib))
    ncout.attrib["history"] *= "; Modified by CliMA (see atmos_dyamond_summer in ClimaArtifacts)"

    lonidx = 1:skip:ncin.dim["lon"]
    latidx = reverse(1:skip:ncin.dim["lat"])
    # In this dataset vertical levels are ordered in the direction of 
    # increasing pressure (decreasing elevation). This is being reordered
    # to stay consistent with our code which orders vertical levels in the 
    # direction of increasing elevation
    zidx_center = reverse(1:ncin.dim["lev"])
    zidx_face = reverse(1:ncin.dim["lev"]+1)

    nlon = length(lonidx)
    nlat = length(latidx)
    source_nz_center = length(zidx_center)

    @inbounds begin
        # get source z surface
        z_surface = FT.(ncin["z"][lonidx, latidx, 1, 1] ./ grav)
        # get source air Temperature
        source_t_center = FT.(ncin["t"][lonidx, latidx, zidx_center, 1])
        # get source q_tot (specific humidity)
        source_q_tot_center = FT.(ncin["q"][lonidx, latidx, zidx_center, 1])
        #source_qp_center = TD.PhasePartition.(source_q_tot_center)
        # surface pressure
        surface_pressure = FT.(exp.(ncin["lnsp"][lonidx, latidx, 1, 1]))
        # get source pressure at center
        hyam = FT.(ncin["hyam"][zidx_center])
        hybm = FT.(ncin["hybm"][zidx_center])
        source_p_center = compute_source_pressure(surface_pressure, hyam, hybm)
        # get source pressure at faces
        hyai = FT.(ncin["hyai"][zidx_face])
        hybi = FT.(ncin["hybi"][zidx_face])
        source_p_face = compute_source_pressure(surface_pressure, hyai, hybi)
        # compute z at faces
        source_z_face = compute_z_face(source_p_center, source_p_face, source_t_center, source_q_tot_center, z_surface)
        # compute z at centers
        source_z_center = compute_z_center(source_z_face)

        nz = size(source_z_center, 3)

        # create a target z grid with nz points
        target_z = FT.(Plvl_inv.(range(Plvl(z_min), Plvl(z_max), nz)))
        # defining dimensions
        defDim(ncout, "lon", nlon)
        defDim(ncout, "lat", nlat)
        defDim(ncout, "z", nz)
        # longitude
        lon = defVar(ncout, "lon", FT, ("lon",), attrib = ncin["lon"].attrib)
        lon[:] = Array{FT}(ncin["lon"][lonidx])
    
        # latitude
        lat = defVar(ncout, "lat", FT, ("lat",), attrib = ncin["lat"].attrib)
        lat[:] = Array{FT}(ncin["lat"][latidx])

        z = defVar(ncout, "z", FT, ( "z",), attrib = OrderedDict(
            "Datatype" => string(FT),
            "standard_name" => "altitude",
            "short_name" => "z",
            "long_name" => "altitude",
            "units" => "m",
            ),
        )
        z[:] = target_z
        # p (pressure)
        p = defVar(ncout, "p", FT, ("lon", "lat", "z",), attrib = OrderedDict(
            "Datatype" => string(FT),
            "standard_name" => "pressure",
            "long_name" => "pressure",
            "short_name" => "pfull",
            "units" => "Pa",
            ),
        )
        p[:, :, :] = interpz_3d(target_z, source_z_face, source_p_face)
        # u (eastward_wind)
        u = defVar(ncout, "u", FT, ("lon", "lat", "z",), attrib = ncin["u"].attrib)
        u[:, :, :] = interpz_3d(target_z, source_z_center, FT.(ncin["u"][lonidx, latidx, zidx_center, 1]))

        # v (northward_wind)
        v = defVar(ncout, "v", FT, ("lon", "lat", "z",), attrib = ncin["v"].attrib)
        v[:, :, :] = interpz_3d(target_z, source_z_center, FT.(ncin["v"][lonidx, latidx, zidx_center, 1]))
    
        # w (vertical velocity)
        w = defVar(ncout, "w", FT, ("lon", "lat", "z",), attrib = ncin["w"].attrib)
        w[:, :, :] = interpz_3d(target_z, source_z_center, FT.(ncin["w"][lonidx, latidx, zidx_center, 1]))
    
        # t (air_temperature)
        t = defVar(ncout, "t", FT, ("lon", "lat", "z",), attrib = ncin["t"].attrib)
        t[:, :, :] = interpz_3d(target_z, source_z_center, FT.(ncin["t"][lonidx, latidx, zidx_center, 1]))
    
        # q (specific_humidity)
        q = defVar(ncout, "q", FT, ("lon", "lat", "z",), attrib = ncin["q"].attrib)
        q[:, :, :] = max.(interpz_3d(target_z, source_z_center, FT.(ncin["q"][lonidx, latidx, zidx_center, 1])), FT(0))

        # clwc (Specific cloud liquid water content)
        clwc = defVar(ncout, "clwc", FT, ("lon", "lat", "z",), attrib = ncin["clwc"].attrib)
        clwc[:, :, :] = max.(interpz_3d(target_z, source_z_center, FT.(ncin["clwc"][lonidx, latidx, zidx_center, 1])), FT(0))

        # ciwc (Specific cloud ice water content)
        ciwc = defVar(ncout, "ciwc", FT, ("lon", "lat", "z",), attrib = ncin["ciwc"].attrib)
        ciwc[:, :, :] = max.(interpz_3d(target_z, source_z_center, FT.(ncin["ciwc"][lonidx, latidx, zidx_center, 1])), FT(0))

        # crwc (Specific rain water content)
        crwc = defVar(ncout, "crwc", FT, ("lon", "lat", "z",), attrib = ncin["crwc"].attrib)
        crwc[:, :, :] = max.(interpz_3d(target_z, source_z_center, FT.(ncin["crwc"][lonidx, latidx, zidx_center, 1])), FT(0))

        # cswc (Specific snow water content)
        cswc = defVar(ncout, "cswc", FT, ("lon", "lat", "z",), attrib = ncin["cswc"].attrib)
        cswc[:, :, :] = max.(interpz_3d(target_z, source_z_center, FT.(ncin["cswc"][lonidx, latidx, zidx_center, 1])), FT(0))

        # tsn (temperature_in_surface_snow)
        tsn = defVar(ncout, "tsn", FT, ("lon", "lat",), attrib = ncin["tsn"].attrib)
        tsn[:, :] = FT.(ncin["tsn"][lonidx, latidx, 1])

        # skt (skin temperature)
        skt = defVar(ncout, "skt", FT, ("lon", "lat",), attrib = ncin["skt"].attrib)
        skt[:, :] = FT.(ncin["skt"][lonidx, latidx, 1])

        # sst (sea surface temperature)
        sst = defVar(ncout, "sst", FT, ("lon", "lat",), attrib = ncin["sst"].attrib)
        sst[:, :] = ncin["sst"][lonidx, latidx, 1]

        # stl1 (soil temperature level 1)
        stl1 = defVar(ncout, "stl1", FT, ("lon", "lat",), attrib = ncin["stl1"].attrib)
        stl1[:, :] = FT.(ncin["stl1"][lonidx, latidx, 1])

        # stl2 (soil temperature level 2)
        stl2 = defVar(ncout, "stl2", FT, ("lon", "lat",), attrib = ncin["stl2"].attrib)
        stl2[:, :] = FT.(ncin["stl2"][lonidx, latidx, 1])

        # stl3 (soil temperature level 3)
        stl3 = defVar(ncout, "stl3", FT, ("lon", "lat",), attrib = ncin["stl3"].attrib)
        stl3[:, :] = FT.(ncin["stl3"][lonidx, latidx, 1])

        # stl4 (soil temperature level 4)
        stl4 = defVar(ncout, "stl4", FT, ("lon", "lat",), attrib = ncin["stl4"].attrib)
        stl4[:, :] = FT.(ncin["stl4"][lonidx, latidx, 1])

        # sd (lwe_thickness_of_surface_snow_amount)
        sd = defVar(ncout, "sd", FT, ("lon", "lat",), attrib = ncin["sd"].attrib)
        sd[:, :] = FT.(ncin["sd"][lonidx, latidx, 1])

        # rsn (snow density)
        rsn = defVar(ncout, "rsn", FT, ("lon", "lat",), attrib = ncin["rsn"].attrib)
        rsn[:, :] = FT.(ncin["rsn"][lonidx, latidx, 1])

        # asn (snow albedo)
        asn = defVar(ncout, "asn", FT, ("lon", "lat",), attrib = ncin["asn"].attrib)
        asn[:, :] = FT.(ncin["asn"][lonidx, latidx, 1])

        # src (skin reservoir content)
        src = defVar(ncout, "src", FT, ("lon", "lat",), attrib = ncin["src"].attrib)
        src[:, :] = FT.(ncin["src"][lonidx, latidx, 1])

        # ci (Sec-ice cover)
        ci = defVar(ncout, "ci", FT, ("lon", "lat",), attrib = ncin["ci"].attrib)
        ci[:, :] = FT.(ncin["ci"][lonidx, latidx, 1])

        # swvl1 (volumetric soil water layer 1)
        swvl1 = defVar(ncout, "swvl1", FT, ("lon", "lat",), attrib = ncin["swvl1"].attrib)
        swvl1[:, :] = FT.(ncin["swvl1"][lonidx, latidx, 1])

        # swvl2 (volumetric soil water layer 2)
        swvl2 = defVar(ncout, "swvl2", FT, ("lon", "lat",), attrib = ncin["swvl2"].attrib)
        swvl2[:, :] = FT.(ncin["swvl2"][lonidx, latidx, 1])

        # swvl3 (volumetric soil water layer 3)
        swvl3 = defVar(ncout, "swvl3", FT, ("lon", "lat",), attrib = ncin["swvl3"].attrib)
        swvl3[:, :] = FT.(ncin["swvl3"][lonidx, latidx, 1])

        # swvl4 (volumetric soil water layer 4)
        swvl4 = defVar(ncout, "swvl4", FT, ("lon", "lat",), attrib = ncin["swvl4"].attrib)
        swvl4[:, :] = FT.(ncin["swvl4"][lonidx, latidx, 1])

        # slt (soil type)
        slt = defVar(ncout, "slt", FT, ("lon", "lat",), attrib = ncin["slt"].attrib)
        slt[:, :] = FT.(ncin["slt"][lonidx, latidx, 1])

        # lsm (land-sea mask)
        lsm = defVar(ncout, "lsm", FT, ("lon", "lat",), attrib = ncin["lsm"].attrib)
        lsm[:, :] = FT.(ncin["lsm"][lonidx, latidx, 1])

        # sr (surface roughness length)
        sr = defVar(ncout, "sr", FT, ("lon", "lat",), attrib = ncin["sr"].attrib)
        sr[:, :] = FT.(ncin["sr"][lonidx, latidx, 1])

        # cvl (low vegetation cover)
        cvl = defVar(ncout, "cvl", FT, ("lon", "lat",), attrib = ncin["cvl"].attrib)
        cvl[:, :] = FT.(ncin["cvl"][lonidx, latidx, 1])

        # cvh (high vegetation cover)
        cvh = defVar(ncout, "cvh", FT, ("lon", "lat",), attrib = ncin["cvh"].attrib)
        cvh[:, :] = FT.(ncin["cvh"][lonidx, latidx, 1])

        # sdor (standard deviation or orography)
        sdor = defVar(ncout, "sdor", FT, ("lon", "lat",), attrib = ncin["sdor"].attrib)
        sdor[:, :] = FT.(ncin["sdor"][lonidx, latidx, 1])

        # isor (anisotropy of sub-grid scale orography)
        isor = defVar(ncout, "isor", FT, ("lon", "lat",), attrib = ncin["isor"].attrib)
        isor[:, :] = FT.(ncin["isor"][lonidx, latidx, 1])

        # anor (angle of sub-grid scale orography)
        anor = defVar(ncout, "anor", FT, ("lon", "lat",), attrib = ncin["anor"].attrib)
        anor[:, :] = FT.(ncin["anor"][lonidx, latidx, 1])

        # slor (slope of sub-grid scale orography)
        slor = defVar(ncout, "slor", FT, ("lon", "lat",), attrib = ncin["slor"].attrib)
        slor[:, :] = FT.(ncin["slor"][lonidx, latidx, 1])
    end
    close(ncout)
    return nothing
end

println("creating initial conditions for 0.98⁰ resolution")

artifact_dir_p98deg = artifact_name_p98deg = "DYAMOND_SUMMER_ICS_p98deg"

if !isdir(artifact_dir_p98deg)
    mkdir(artifact_dir_p98deg)
end
file_path_p98deg = joinpath(@__DIR__, artifact_dir_p98deg, artifact_name_p98deg * ".nc")

@time create_initial_conditions(FILE_PATH, file_path_p98deg, skip=7)

create_artifact_guided(artifact_dir_p98deg, artifact_name = artifact_name_p98deg, append = true)


println("creating initial conditions for 0.14⁰ resolution")

artifact_dir_p14deg = artifact_name_p14deg = "DYAMOND_SUMMER_ICS_p14deg"

if !isdir(artifact_dir_p14deg)
    mkdir(artifact_dir_p14deg)
end
file_path_p14deg = joinpath(@__DIR__, artifact_dir_p14deg, artifact_name_p14deg * ".nc")

@time create_initial_conditions(FILE_PATH, file_path_p14deg, skip=1)

create_artifact_guided(artifact_dir_p14deg, artifact_name = artifact_name_p14deg, append = true)
