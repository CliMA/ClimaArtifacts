using Dates
using Downloads
using NCDatasets

using ClimaArtifactsHelper

FILE_URLs = [
    "http://aims3.llnl.gov/thredds/fileServer/user_pub_work/input4MIPs/CMIP6/CMIP/UReading/UReading-CCMI-1-0/atmos/mon/vmro3/gn/v20160711/vmro3_input4MIPs_ozone_CMIP_UReading-CCMI-1-0_gn_185001-189912.nc",
    "http://aims3.llnl.gov/thredds/fileServer/user_pub_work/input4MIPs/CMIP6/CMIP/UReading/UReading-CCMI-1-0/atmos/mon/vmro3/gn/v20160711/vmro3_input4MIPs_ozone_CMIP_UReading-CCMI-1-0_gn_190001-194912.nc",
    "http://aims3.llnl.gov/thredds/fileServer/user_pub_work/input4MIPs/CMIP6/CMIP/UReading/UReading-CCMI-1-0/atmos/mon/vmro3/gn/v20160711/vmro3_input4MIPs_ozone_CMIP_UReading-CCMI-1-0_gn_195001-199912.nc",
    "http://aims3.llnl.gov/thredds/fileServer/user_pub_work/input4MIPs/CMIP6/CMIP/UReading/UReading-CCMI-1-0/atmos/mon/vmro3/gn/v20160711/vmro3_input4MIPs_ozone_CMIP_UReading-CCMI-1-0_gn_200001-201412.nc",
    "http://aims3.llnl.gov/thredds/fileServer/user_pub_work/input4MIPs/CMIP6/ScenarioMIP/UReading/UReading-CCMI-ssp585-1-0/atmos/mon/vmro3/gn/v20181101/vmro3_input4MIPs_ozone_ScenarioMIP_UReading-CCMI-ssp585-1-0_gn_201501-204912.nc",
            ]
FILE_PATHs = [
    "vmro3_input4MIPs_ozone_CMIP_UReading-CCMI-1-0_gn_185001-189912.nc",
    "vmro3_input4MIPs_ozone_CMIP_UReading-CCMI-1-0_gn_190001-194912.nc",
    "vmro3_input4MIPs_ozone_CMIP_UReading-CCMI-1-0_gn_195001-199912.nc",
    "vmro3_input4MIPs_ozone_CMIP_UReading-CCMI-1-0_gn_200001-201412.nc",
    "vmro3_input4MIPs_ozone_ScenarioMIP_UReading-CCMI-ssp585-1-0_gn_201501-204912.nc",
             ]

const H_EARTH = 7000.0
const P0 = 1e5
const HPA_TO_PA = 100.0

FT = Float32

Plvl_inv(P) = -H_EARTH * log(P / P0)

function create_ozone(FT, infile_paths, outfile_path; small = false)
    ncin = NCDataset(infile_paths, aggdim = "time")
    ncout = NCDataset(outfile_path, "c")

    THINNING_FACTOR = 1
    MAX_TIME = length(ncin["time"])

    if small
        THINNING_FACTOR = 8
        MAX_TIME = 12
    end

    defDim(ncout, "lon", Int(ceil(length(ncin["lon"]) // THINNING_FACTOR)))
    defDim(ncout, "lat", Int(ceil(length(ncin["lat"]) // THINNING_FACTOR)))
    defDim(ncout, "z", Int(ceil(length(ncin["plev"]) // THINNING_FACTOR)))
    defDim(ncout, "time", small ? 2MAX_TIME : MAX_TIME)

    lon = defVar(ncout, "lon", FT, ("lon",), attrib = ncin["lon"].attrib)
    lon[:] = Array(ncin["lon"])[begin:THINNING_FACTOR:end]

    lat = defVar(ncout, "lat", FT, ("lat",), attrib = ncin["lat"].attrib)
    lat[:] = Array(ncin["lat"])[begin:THINNING_FACTOR:end]

    z = defVar(ncout, "z", FT, ("z",))
    plevin = ncin["plev"][begin:THINNING_FACTOR:end] .* HPA_TO_PA
    @. z = Plvl_inv(plevin)
    z.attrib["long_name"] = "altitude"
    z.attrib["units"] = "meters"

    time_ = defVar(ncout, "time", FT, ("time",), attrib = ncin["time"].attrib)
    # The ozone files have different calendars for the time variable, here we convert it to DateTime
    if small
        # First and last year
        time_[:] = vcat(
            reinterpret.(Ref(Dates.DateTime), Array(ncin["time"])[begin:MAX_TIME]), 
            reinterpret.(Ref(Dates.DateTime), Array(ncin["time"])[(end-MAX_TIME+1):end]),
        )
    else
        time_[:] = reinterpret.(Ref(Dates.DateTime), Array(ncin["time"])[begin:MAX_TIME])
    end

    defVar(
        ncout,
        "vmro3",
        FT,
        ("lon", "lat", "z", "time"),
        attrib = ncin["vmro3"].attrib,
    )
    if small
        ncout["vmro3"][:,:,:,begin:MAX_TIME] = ncin["vmro3"][begin:THINNING_FACTOR:end,begin:THINNING_FACTOR:end,begin:THINNING_FACTOR:end,begin:MAX_TIME]
        ncout["vmro3"][:,:,:,(end-MAX_TIME+1):end] = ncin["vmro3"][begin:THINNING_FACTOR:end,begin:THINNING_FACTOR:end,begin:THINNING_FACTOR:end,(end-MAX_TIME+1):end]
    else
        ncout["vmro3"][:,:,:,:] = ncin["vmro3"][begin:THINNING_FACTOR:end,begin:THINNING_FACTOR:end,begin:THINNING_FACTOR:end,begin:MAX_TIME]
    end

    close(ncin)
    close(ncout)
end

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
        ozone_file = Downloads.download(url; progress = download_rate_callback())
        Base.mv(ozone_file, path)
    end
end

# The ozone files have different variable names for the bounds, e.g. "plev_bounds" vs "bounds_plev",
# This causes issues when opening the files with NCDatasets aggdim, so we add some variables if they are missing
for file_path in FILE_PATHs
    ncin = NCDataset(file_path, "a")
    for var in ("plev", "lat", "lon")
        haskey(ncin, "bounds_$var") || defVar(ncin, "bounds_$var", FT, (var, "bnds"))
    end
    close(ncin)
end

create_ozone(FT, FILE_PATHs, joinpath(output_dir, "ozone_concentrations.nc"))

@info "Data file generated!"
create_artifact_guided(output_dir; artifact_name = basename(@__DIR__))

output_dir_lowres = "ozone_artifact_lowres"

if isdir(output_dir_lowres)
    @warn "$output_dir_lowres already exists. Content will end up in the artifact and may be overwritten."
    @warn "Abort this calculation, unless you know what you are doing."
else
    mkdir(output_dir_lowres)
end

create_ozone(
    FT,
    FILE_PATHs,
    joinpath(output_dir_lowres, "ozone_concentrations_lowres.nc"),
    small = true,
)

create_artifact_guided(
    output_dir_lowres;
    artifact_name = basename(@__DIR__) * "_lowres",
    append = true
)
