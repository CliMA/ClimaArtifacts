using Downloads

using ClimaArtifactsHelper

const FILE_URLS = [
    "https://aims3.llnl.gov/thredds/fileServer/css03_data/CMIP6/CMIP/NCAR/CESM2/historical/r1i1p1f1/Amon/rsus/gn/v20190308/rsus_Amon_CESM2_historical_r1i1p1f1_gn_185001-201412.nc",
    "https://aims3.llnl.gov/thredds/fileServer/css03_data/CMIP6/CMIP/NCAR/CESM2/historical/r1i1p1f1/Amon/rsds/gn/v20190308/rsds_Amon_CESM2_historical_r1i1p1f1_gn_185001-201412.nc",
]

const FILE_PATHS = [
    "rsus_Amon_CESM2_historical_r1i1p1f1_gn_185001-201412.nc",
    "rsds_Amon_CESM2_historical_r1i1p1f1_gn_185001-201412.nc",
]

const OUTPUT_FILES = [
    "sw_albedo_Amon_CESM2_historical_r1i1p1f1_gn_185001-201412_v2_no-nans.nc",
    "bareground_albedo.nc"
    ]

output_dir = basename(@__DIR__) * "_artifact"
if isdir(output_dir)
    @warn "$output_dir already exists. Content will end up in the artifact and may be overwritten."
    @warn "Abort this calculation, unless you know what you are doing."
else
    mkdir(output_dir)
end

for (file_path, file_url) in zip(FILE_PATHS, FILE_URLS)
    println(file_url)
    println(file_path)
    if !isfile(file_path)
        @info "$file_path not found, downloading it (might take a while)"
        # The server has poor certificates, so we have to disable verification
        downloader = Downloads.Downloader()
        downloader.easy_hook =
            (easy, info) -> Downloads.Curl.setopt(
                easy,
                Downloads.Curl.CURLOPT_SSL_VERIFYPEER,
                false,
            )
        println(file_url)
        println(file_path)
        downloaded_file = Downloads.download(file_url; downloader, progress = download_rate_callback())
        Base.mv(downloaded_file, file_path)
    end
end

include("calculate_sw_alb.jl")
include("calculate_bareground_alb.jl")

for output_file in OUTPUT_FILES
    output_path = joinpath(output_dir, basename(output_file))
    # set force to true to overwrite existing output files
    Base.cp(output_file, output_path; force=true)
end

create_artifact_guided(
    output_dir;
    artifact_name = basename(@__DIR__),
)
