using Downloads 

using ClimaArtifactsHelper


const FILE_URL = "https://caltech.box.com/shared/static/elv5ksf3av3kum9552jxhnmlgu7vxr8u.nc"
const FILE_PATH = "HadGEM2-A_amip.2004-2008.07.nc"

output_dir = "cfsite_gcm_forcing_artifact"
if isdir(output_dir)
    @warn "$output_dir already exists. Content will end up in the artifact and may be overwritten."
    @warn "Abort this calculation, unless you know what you are doing."
else
    mkdir(output_dir)
end

if !isfile(FILE_PATH)
    @info "$FILE_PATH not found, downloading it (might take a while)"
    cfsite_gcm_forcing_file = Downloads.download(FILE_URL)
    Base.mv(cfsite_gcm_forcing_file, FILE_PATH)
    Base.cp(FILE_PATH, joinpath(output_dir, basename(FILE_PATH)))
end

@info "GCM forcing file generated!"
create_artifact_guided(output_dir; artifact_name = basename(@__DIR__))
