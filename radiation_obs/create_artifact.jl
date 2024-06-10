using Downloads

using ClimaArtifactsHelper

# This file is in a zip file on caltech data archive: 
# https://data.caltech.edu/records/z24s9-nqc90/files/Climate_Model_RMSE_Analysis.zip?download=1
const FILE_URL = "https://caltech.box.com/shared/static/hd5emjq0ryzn1kdqddfwhoieqrc2pcpj.nc"
const FILE_PATH = "CERES_EBAF-TOA_Ed4.2_Subset_200003-202303.g025.nc"

output_dir = "radiation_obs_artifact"
if isdir(output_dir)
    @warn "$output_dir already exists. Content will end up in the artifact and may be overwritten."
    @warn "Abort this calculation, unless you know what you are doing."
else
    mkdir(output_dir)
end

if !isfile(FILE_PATH)
    @info "$FILE_PATH not found, downloading it (might take a while)"
    precipitation_obs_file = Downloads.download(FILE_URL)
    Base.mv(precipitation_obs_file, FILE_PATH)
    Base.cp(FILE_PATH, joinpath(output_dir, basename(FILE_PATH)))
end

@info "Data file generated!"
create_artifact_guided(output_dir; artifact_name = basename(@__DIR__))
