using ClimaArtifactsHelper
using Downloads

FILE_NAME = "tv_forcing_17.0_-149.0_20070701.nc"
FILE_URL = "https://caltech.box.com/shared/static/src2lmtc74rc3d0g3umecqgwthgyne35.nc"

output_dir = basename(@__DIR__) * "_artifact"

if isdir(output_dir)
    @warn "$output_dir already exists. Content will end up in the artifact and may be overwritten."
    @warn "Abort this calculation, unless you know what you are doing."
else
    mkdir(output_dir)
end
output_path = joinpath(output_dir, FILE_NAME)
if !isfile(output_path)
    @info "$FILE_NAME not found, downloading it (might take a while)"
    downloaded_file = Downloads.download(FILE_URL; progress = download_rate_callback())
    Base.mv(downloaded_file, output_path)
end

output_artifacts = "OutputArtifacts.toml"
artifact_name = basename(@__DIR__)
hash = bytes2hex(ClimaArtifactsHelper.sha1(artifact_name))
ClimaArtifactsHelper._recommend_uploading_to_cluster(hash, artifact_name, output_dir)
artifacts_str = "[$artifact_name]\ngit-tree-sha1 = \"$hash\"\n"
println(artifacts_str)

open(output_artifacts, "w") do file
    write(file, artifacts_str)
end

@info "Artifact string saved to $output_artifacts"
