# Note: This script must be run on Caltech's Central cluster. If you need to run
#  it elsewhere, you can do so by changing the Matlab path used in the bash script.
using ClimaArtifactsHelper

# Set the output directory
output_dir = basename(@__DIR__) * "_artifact"
if isdir(output_dir)
    @warn "$output_dir already exists. Content will end up in the artifact and may be overwritten."
    @warn "Abort this calculation, unless you know what you are doing."
else
    mkdir(output_dir)
end

# Run the bash script to create the artifact
run(`bash get_bonan_data.sh $output_dir`)

@info "Data file generated!"

create_artifact_guided(
    output_dir;
    artifact_name = basename(@__DIR__),
)
