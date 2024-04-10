using Downloads
using NCDatasets
using ProgressMeter

using ClimaArtifactsHelper

const FILE_URL = "https://caltech.box.com/shared/static/zubipz298q5ar5rpfais8c0ymtfyz2oc.nc"
const FILE_PATH = "gfdl_ogw.nc"

output_dir = "gfdl_orographic_gravity_wave_artifact"
if isdir(output_dir)
    @warn "$output_dir already exists. Content will end up in the artifact and may be overwritten."
    @warn "Abort this calculation, unless you know what you are doing."
else
    mkdir(output_dir)
end

if !isfile(FILE_PATH)
    @info "$FILE_PATH not found, downloading it (might take a while)"
    gfdl_ogw_file = Downloads.download(FILE_URL)
    Base.mv(gfdl_ogw_file, FILE_PATH)
end

@info "Orographic gravity-wave (GFDL) dataset is ready!"
create_artifact_guided(output_dir; artifact_name = basename(@__DIR__))
