using ClimaArtifactsHelper
using Downloads

# Set the output directory
output_dir = basename(@__DIR__) * "_artifact"
if isdir(output_dir)
    @warn "$output_dir already exists. Content will end up in the artifact and may be overwritten."
    @warn "Abort this calculation, unless you know what you are doing."
else
    mkdir(output_dir)
end

# Define the URLs and filenames for the two files
const FILE_URLS = [
    "https://caltech.box.com/shared/static/56vlrnjoh8gto0z9xa43x6r56iechyl3.csv",
    "https://caltech.box.com/shared/static/xmkahp2dfuyjif7aw5pam3rscasfo070.csv"
]

const FILE_NAMES = [
    "inputs.csv",
    "outputs.csv"
]

@info "Downloading files for P-model unit tests..."

# Download each file
for (url, filename) in zip(FILE_URLS, FILE_NAMES)
    output_path = joinpath(output_dir, filename)
    @info "Downloading $filename from $url"
    Downloads.download(url, output_path; progress = download_rate_callback())
    @info "Successfully downloaded $filename"
end

@info "All data files downloaded!"

create_artifact_guided(
    output_dir;
    artifact_name = basename(@__DIR__),
)
