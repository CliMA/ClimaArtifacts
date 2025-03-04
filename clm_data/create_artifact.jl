using Downloads

using ClimaArtifactsHelper

const FILE_URLS = [
    "https://svn-ccsm-inputdata.cgd.ucar.edu/trunk/inputdata/lnd/clm2/surfdata_map/surfdata_0.9x1.25_16pfts__CMIP6_simyr2000_c170616.nc",
    "https://svn-ccsm-inputdata.cgd.ucar.edu/trunk/inputdata/lnd/clm2/surfdata_map/surfdata_0.125x0.125_16pfts_simyr2000_c151014.nc",
    "https://svn-ccsm-inputdata.cgd.ucar.edu/trunk/inputdata/lnd/clm2/pftdata/pft-physiology.c110225.nc",
    "https://svn-ccsm-inputdata.cgd.ucar.edu/trunk/inputdata/lnd/clm2/paramdata/clm5_params.c171117.nc",
]
const FILE_PATHS = [
    "surfdata_0.9x1.25_16pfts__CMIP6_simyr2000_c170616.nc",
    "surfdata_0.125x0.125_16pfts_simyr2000_c151014.nc",
    "pft-physiology.c110225.nc",
    "clm5_params.c171117.nc",
]
const OUTPUT_FILES =
    ["dominant_PFT_map.nc", "vegetation_properties_map.nc", "soil_properties_map.nc"]

output_dir = basename(@__DIR__) * "_0.9x1.25_artifact"
output_dir_highres = basename(@__DIR__) * "_0.125x0.125_artifact"
for dir in [output_dir, output_dir_highres]
    if isdir(dir)
        @warn "$dir already exists. Content will end up in the artifact and may be overwritten."
        @warn "Abort this calculation, unless you know what you are doing."
    else
        mkdir(dir)
    end
end

for (file_path, file_url) in zip(FILE_PATHS, FILE_URLS)
    println(file_url)
    println(file_path)
    if !isfile(file_path)
        @info "$file_path not found, downloading it (might take a while)"
        # The server has poor certificates, so we have to disable verification
        downloader = Downloads.Downloader()
        println(file_url)
        println(file_path)
        downloaded_file =
            Downloads.download(file_url; downloader, progress = download_rate_callback())
        Base.mv(downloaded_file, file_path)
    end
end

for output_file in OUTPUT_FILES
    isfile(output_file) && rm(output_file)
end

run(`python dominant_pft.py`)
run(`python pft_variables.py`)
run(`python soil_variables.py`)

for output_file in OUTPUT_FILES
    output_path = joinpath(output_dir, output_file)
    # set force to true to overwrite existing output files
    Base.mv(output_file, output_path; force = true)
end

run(`python dominant_pft.py -d`)
run(`python pft_variables.py -d`)
run(`python soil_variables.py -d`)

for output_file in OUTPUT_FILES
    output_path = joinpath(output_dir_highres, output_file)
    # set force to true to overwrite existing output files
    Base.mv(output_file, output_path; force = true)
end

create_artifact_guided(output_dir; artifact_name = basename(@__DIR__) * "_0.9x1.25")

create_artifact_guided(
    output_dir_highres;
    artifact_name = basename(@__DIR__) * "_0.125x0.125",
    append = true,
)
