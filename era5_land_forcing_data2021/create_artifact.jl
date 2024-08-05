using Downloads
using NCDatasets
using ClimaArtifactsHelper

# This file is 20GB
output_dir = "era5_land_forcing2021_artifact"
const FILE_URL = "https://caltech.box.com/shared/static/yi4dlo9wug9a4yz2ckqfiqh26a61u55y.nc"
const FILE_PATH = joinpath(output_dir, "era5_2021_0.9x1.25.nc")

if isdir(output_dir)
    @warn "$output_dir already exists. Content will end up in the artifact and may be overwritten."
    @warn "Abort this calculation, unless you know what you are doing."
else
    mkdir(output_dir)
end

if !isfile(FILE_PATH)
    @info "$FILE_PATH not found, downloading it (might take a while)"
    forcing_file = Downloads.download(FILE_URL)
    Base.mv(forcing_file, FILE_PATH)
end

@info "Raw data file generated!"
rawdata_path = FILE_PATH

function process_raw_era5data(rawdata_path, processeddata_path)
    FT = Float32
    ncin = NCDataset(rawdata_path)
    ncout = NCDataset(processeddata_path,"c")

    defDim(ncout, "lon", length(ncin["lon"]))
    defDim(ncout, "lat", length(ncin["lat"]))
    defDim(ncout, "time", length(ncin["time"]))

    lon = defVar(ncout, "lon", FT, ("lon",), attrib = ncin["lon"].attrib)
    lon[:] = Array(ncin["lon"])

    lat = defVar(ncout, "lat", FT, ("lat",), attrib = ncin["lat"].attrib)
    lat[:] = Array(ncin["lat"])

    time_ = defVar(ncout, "time", FT, ("time",), attrib = ncin["time"].attrib)
    time_[:] = Array(ncin["time"])
    @show("Adding wind speed...")
    ws = defVar(
            ncout,
            "ws",
            FT,
            ("lon", "lat", "time"),
            attrib =Dict("long_name" => "Neutral wind speed at 10m", "units" => "m s**-1"),
        )
    ws[:, :, :] = @. sqrt((ncin["v10n"][:,:,:]^2 + ncin["u10n"][:,:,:]^2))
    @show("Adding rain...")

    rf = defVar(
        ncout,
        "rf",
        FT,
        ("lon", "lat", "time"),
        attrib =Dict("long_name" => "Accumulated non-snow precipitation", "units" => "m"),
    )
    rf[:, :, :] = ncin["tp"][:,:,:] .- ncin["sf"][:,:,:];
    @show("Adding q...")

    q = defVar(
        ncout,
        "q",
        FT,
        ("lon", "lat", "time"),
        attrib =Dict("long_name" => "Specific humidity", "units" => "kg kg**-1"),
    )

    function relative_humidity(dewpoint_temperature, temperature)
        # convert temperature to C
        Td = dewpoint_temperature-273.15
        T = temperature - 273.15
        c = 243.04 # C
        b = 17.625 # unitless
        γ = Td*b/(c+Td)
        RH = exp(γ - b*T/(c+T))
        return RH # not a percentage
    end


    function saturation_vapor_pressure(T)
        LH_v0 = 2_500_800
        cp_v = 1859
        cp_l = 4181
        LH_0 = LH_v0
        Δcp = (cp_v - cp_l)
        press_triple = 611.657
        R_v = 461.522
        T_triple = 273.16
        T_0 = 273.16
        return press_triple * (T / T_triple)^(Δcp / R_v) * exp((LH_0 - Δcp * T_0) / R_v * (1 / T_triple - 1 / T))
    end

    function specific_humidity(esat, rh)
        e = rh * esat
        q = 0.622 * e / (101325 - 0.378 * e)
        return q
    end

    RH = relative_humidity.(ncin["d2m"][:,:,:], ncin["t2m"][:,:,:]);
    esat = saturation_vapor_pressure.(ncin["t2m"][:,:,:]);
    q[:,:,:] = specific_humidity.(esat, RH);

    for (k,v) in ncin.attrib
        ncout.attrib[k] = v
    end

   ncout.attrib["Modifications"] = "Modified by the Clima Land team (unit conversions, e.g.), 2024"
    close(ncout)
end
function process_raw_LAIdata(rawdata_path, processeddata_path)
    FT = Float32
    ncin = NCDataset(rawdata_path)
    ncout = NCDataset(processeddata_path,"c")
    n_hours = length(ncin["time"]); # Raw data is hourly
    # We'll save LAI every week, since it changes slowly
    ntime = Int(floor(n_hours/(7*24)))
    times = (0:1:(ntime-1)).*7 .*24 .+ 1
    defDim(ncout, "lon", length(ncin["lon"]))
    defDim(ncout, "lat", length(ncin["lat"]))
    defDim(ncout, "time", ntime)

    lon = defVar(ncout, "lon", FT, ("lon",), attrib = ncin["lon"].attrib)
    lon[:] = Array(ncin["lon"])

    lat = defVar(ncout, "lat", FT, ("lat",), attrib = ncin["lat"].attrib)
    lat[:] = Array(ncin["lat"])

    time_ = defVar(ncout, "time", FT, ("time",), attrib = ncin["time"].attrib)
    time_[:] = Array(ncin["time"][times]) 
    @show("Adding LAI...")
    lai = defVar(
            ncout,
            "lai",
            FT,
            ("lon", "lat", "time"),
            attrib =Dict("long_name" => "Total leaf area index", "units" => "m**2 m**-2"),
        )
    lai[:, :, :] = ncin["lai_hv"][:,:,times] .+ ncin["lai_lv"][:,:,times];
    for (k,v) in ncin.attrib
        ncout.attrib[k] = v
    end

    ncout.attrib["Modifications"] = "Modified by the Clima Land team (unit conversions, e.g.), 2024"
    close(ncout)
end


processeddata_path = joinpath(output_dir,"era5_2021_0.9x1.25_clima.nc")
processedlaidata_path = joinpath(output_dir,"era5_lai_2021_0.9x1.25_clima.nc")

process_raw_LAIdata(rawdata_path, processedlaidata_path)
process_raw_era5data(rawdata_path, processeddata_path)

create_artifact_guided(output_dir; artifact_name = basename(@__DIR__))
