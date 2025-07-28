"""
This file generates a hash for the existing fluxnet2015 artifact that is
stored in the Caltech HPC cluster filesystem. As of now, there is unfortunately
no way to reproduce the artifact from a downloadable source. 
"""

using ClimaArtifactsHelper

artifact_name = basename(@__DIR__)

hash = bytes2hex(sha1(artifact_name))
artifacts_str = "[$artifact_name]\ngit-tree-sha1 = \"$hash\"\n"

println("Here is your artifact string. Copy and paste it to your Artifacts.toml. Note that this artifact 
will only be available on the Caltech HPC cluster.")
println()
println(artifacts_str)

println("Add the following entry to the Overrides.toml file you find in `/groups/esm/ClimaArtifacts/artifacts/`")
println()
println("$hash = \"/groups/esm/ClimaArtifacts/artifacts/$artifact_name\"")
println()

output_artifacts = "OutputArtifacts.toml"
open(output_artifacts, "w") do file
    write(file, artifacts_str)
end