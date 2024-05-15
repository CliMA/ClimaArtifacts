using ClimaArtifactsHelper

output_dir = basename(@__DIR__) * "_artifact"
if isdir(output_dir)
    @warn "$output_dir already exists. Content will end up in the artifact and may be overwritten."
    @warn "Abort this calculation, unless you know what you are doing."
else
    mkdir(output_dir)
end

write(joinpath(output_dir, "pi.txt"), "3.1415926535897...")
write(joinpath(output_dir, "2pi.txt"), "2*3.1415926535897...")

create_artifact_guided(
    output_dir;
    artifact_name = basename(@__DIR__),
)
