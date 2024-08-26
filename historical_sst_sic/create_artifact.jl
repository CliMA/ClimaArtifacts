using Downloads

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

for (path, url) in (
    SIC_FILE_PATH => SIC_FILE_URL,
    SST_FILE_PATH => SST_FILE_URL
    )
    if !isfile(path)
        @info "$path not found, downloading it (might take a while)"
        downloaded_file = Downloads.download(url)
        Base.mv(downloaded_file, path)
        Base.cp(path, joinpath(output_dir, basename(path)))
    end
end

@info "Data file generated!"
create_artifact_guided(output_dir; artifact_name = basename(@__DIR__))
