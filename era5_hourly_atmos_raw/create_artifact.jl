using ClimaArtifactsHelper
using Downloads

# TODO: Eventually this should download this data directly from era5 instead of box

# tuples of (url, filename)
SAMPLE_DATA = [
    (
        "https://caltech.box.com/shared/static/s5fjxml4p0ac36v8qq5cu45kvly8so4r.nc",
        "hourly_inst_20070701.nc",
    ),
    (
        "https://caltech.box.com/shared/static/z58e8govm0s0xxvtnxlvyeidjg482d1i.nc",
        "hourly_accum_20070701.nc",
    ),
    (
        "https://caltech.box.com/shared/static/n9c0dfgpehtha1hj6pd1x00o49r70cx0.nc",
        "forcing_and_cloud_hourly_profiles_20070701.nc",
    ),
]

output_dir = basename(@__DIR__) * "_artifact"

if isdir(output_dir)
    @warn "$output_dir already exists. Content will end up in the artifact and may be overwritten."
    @warn "Abort this calculation, unless you know what you are doing."
else
    mkdir(output_dir)
end

for (SAMPLE_URL, FILE_NAME) in SAMPLE_DATA
    output_path = joinpath(output_dir, FILE_NAME)
    if !isfile(output_path)
        @info "$FILE_NAME not found, downloading it (might take a while)"
        downloaded_file = Downloads.download(SAMPLE_URL; progress = download_rate_callback())
        Base.mv(downloaded_file, output_path)
    end
end

create_artifact_guided(output_dir; artifact_name = basename(@__DIR__))
