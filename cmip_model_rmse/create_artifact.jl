using Downloads

using ClimaArtifactsHelper

# The files are generated using the script on caltech data archive: 
# https://data.caltech.edu/records/z24s9-nqc90/files/Climate_Model_RMSE_Analysis.zip?download=1
nvars = 3
file_urls = [
    "https://caltech.box.com/shared/static/mcqusd1t9x8sw2kukhv9m1udc2nulmna.hdf5",
    "https://caltech.box.com/shared/static/f5ornm3pogihk7kziy7825h4emoszf1w.hdf5",
    "https://caltech.box.com/shared/static/mcqusd1t9x8sw2kukhv9m1udc2nulmna.hdf5",
]

file_paths = [
    "pr_rmse_amip.hdf5",
    "rlut_rmse_amip.hdf5",
    "rsut_rmse_amip.hdf5",
]

output_dir = "cmip_model_rmse_artifact"
if isdir(output_dir)
    @warn "$output_dir already exists. Content will end up in the artifact and may be overwritten."
    @warn "Abort this calculation, unless you know what you are doing."
else
    mkdir(output_dir)
end

for i in 1:nvars
    file_path = file_paths[i]
    if !isfile(file_path)
        @info "$file_path not found, downloading it (might take a while)"
        rmse_file = Downloads.download(file_urls[i])
        Base.mv(rmse_file, file_path)
        Base.cp(file_path, joinpath(output_dir, basename(file_path)))
    end
end

@info "Data file generated!"
create_artifact_guided(output_dir; artifact_name = basename(@__DIR__))
