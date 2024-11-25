using Downloads

using NCDatasets
using ClimaArtifactsHelper

# Downloaded from https://gdex.ucar.edu/dataset/158_asphilli.html
const SIC_FILE_URL = "https://gdex.ucar.edu/dataset/158_asphilli/file/MODEL.ICE.HAD187001-198110.OI198111-202206.nc"
const SIC_FILE_PATH = "MODEL.ICE.HAD187001-198110.OI198111-202206.nc"

const SST_FILE_URL = "https://gdex.ucar.edu/dataset/158_asphilli/file/MODEL.SST.HAD187001-198110.OI198111-202206.nc"
const SST_FILE_PATH = "MODEL.SST.HAD187001-198110.OI198111-202206.nc"

output_dir = "historical_sst_sic"
if isdir(output_dir)
    @warn "$output_dir already exists. Content will end up in the artifact and may be overwritten."
    @warn "Abort this calculation, unless you know what you are doing."
else
    mkdir(output_dir)
end

for (path, url) in
    (SIC_FILE_PATH => SIC_FILE_URL, SST_FILE_PATH => SST_FILE_URL)
    if !isfile(path)
        @info "$path not found, downloading it (might take a while)"
        downloaded_file = Downloads.download(url; progress = download_rate_callback())
        Base.mv(downloaded_file, path)
    end
    Base.cp(path, joinpath(output_dir, basename(path)))
end

@info "Data file generated!"
create_artifact_guided(output_dir; artifact_name = basename(@__DIR__))

"""
   thin_artifact(
       filein,
       fileout,
       varname;
       THINNING_FACTOR = 6,
       MAX_TIME = 12,
   )

Take the file in `filein` and write a thinned-down version to `fileout` for the given `varname`.

Thinning means taking one very `THINNING_FACTOR` points, and `2MAX_TIME` times
(at the beginning and end).
"""
function thin_artifact(
    filein,
    fileout,
    varname;
    THINNING_FACTOR = 6,
    MAX_TIME = 12,
)
    ncin = NCDataset(filein)
    ncout = NCDataset(fileout, "c")
    FT = Float32

    defDim(ncout, "lon", Int(ceil(length(ncin["lon"]) // THINNING_FACTOR)))
    defDim(ncout, "lat", Int(ceil(length(ncin["lat"]) // THINNING_FACTOR)))
    defDim(ncout, "time", 2MAX_TIME)

    lon = defVar(ncout, "lon", FT, ("lon",), attrib = ncin["lon"].attrib)
    lon[:] = Array(ncin["lon"])[begin:THINNING_FACTOR:end]

    lat = defVar(ncout, "lat", FT, ("lat",), attrib = ncin["lat"].attrib)
    lat[:] = Array(ncin["lat"])[begin:THINNING_FACTOR:end]

    time_ = defVar(ncout, "time", FT, ("time",), attrib = ncin["time"].attrib)
    # First and last year
    time_[:] = vcat(Array(ncin["time"])[begin:MAX_TIME], Array(ncin["time"])[(end-MAX_TIME+1):end])

    defVar(
        ncout,
        varname,
        FT,
        ("lon", "lat", "time"),
        attrib = ncin[varname].attrib,
    )
    ncout[varname][:, :, begin:MAX_TIME] = ncin[varname][
        begin:THINNING_FACTOR:end,
        begin:THINNING_FACTOR:end,
        begin:MAX_TIME,
    ]
    ncout[varname][:, :, (MAX_TIME+1):end] = ncin[varname][
        begin:THINNING_FACTOR:end,
        begin:THINNING_FACTOR:end,
        (end-MAX_TIME+1):end,
    ]


    close(ncin)
    close(ncout)
end

output_dir_lowres = "historical_sst_sic_lowres"
if isdir(output_dir_lowres)
    @warn "$output_dir_lowres already exists. Content will end up in the artifact and may be overwritten."
    @warn "Abort this calculation, unless you know what you are doing."
else
    mkdir(output_dir_lowres)
end

new_sic_name = replace(SIC_FILE_PATH, ".nc" => "_lowres.nc")
thin_artifact(
    SIC_FILE_PATH,
    joinpath(output_dir_lowres, new_sic_name),
    "SEAICE",
)

new_sst_name = replace(SST_FILE_PATH, ".nc" => "_lowres.nc")
thin_artifact(SST_FILE_PATH, joinpath(output_dir_lowres, new_sst_name), "SST")

@info "Data file generated!"
create_artifact_guided(output_dir_lowres; artifact_name = basename(@__DIR__) * "_lowres", append = true)
