using Downloads
using HDF5

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

const MODELS = ["ACCESS-CM2","ACCESS-ESM1-5","BCC-CSM2-MR","BCC-ESM1","CAMS-CSM1-0","CIESM","CNRM-CM6-1","CNRM-CM6-1-HR",
                "CNRM-ESM2-1","FGOALS-f3-L","GISS-E2-2-G","HadGEM3-GC31-LL","HadGEM3-GC31-MM","INM-CM4-8","INM-CM5-0","KACE-1-0-G",
                "MIROC6","MIROC-ES2L","MPI-ESM1-2-HR","MRI-ESM2-0","NESM3","NorESM2-LM","SAM0-UNICON","UKESM1-0-LL"]

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
        output_hdf5 = joinpath(output_dir, basename(file_path))
        Base.cp(file_path, output_hdf5)

        base_outname = Base.Filesystem.splitext(output_hdf5)[begin]

        # Create CSV file form the HDF5
        h5 = h5open(file_path, "r") do file
            for dataset_name in keys(file)
                output_csv = base_outname * "_$(dataset_name).csv"
                dataset = read(file[dataset_name])
                open(output_csv, "w") do io
                    # Write the header
                    println(io, "# Model,DJF,MAM,JJA,SON,ANN")

                    # Write each row of the dataset
                    for i in 1:length(MODELS)
                        values = join(dataset[:, i], ",")
                        println(io, "$(MODELS[i]),$values")
                    end
                end
            end
        end
    end
end

@info "Data file generated!"
create_artifact_guided(output_dir; artifact_name = basename(@__DIR__))
