# Checks for the artifact directories in this repository. The repository is not a package,
# so run this script directly:
#
#     julia --project=test test/runtests.jl                 # all checks
#     julia --project=test test/runtests.jl directory ...   # all checks, but download only the given directories

import Pkg
import TOML
using Test

const REPO_ROOT = dirname(@__DIR__)

# Top-level directories that do not hold artifacts
const NON_ARTIFACT_DIRS = ["ClimaArtifactsHelper.jl", "screenshots", "test"]

const ARTIFACT_DIRS = filter(readdir(REPO_ROOT)) do dir
    isdir(joinpath(REPO_ROOT, dir)) && !startswith(dir, ".") && dir ∉ NON_ARTIFACT_DIRS
end

const OUTPUT_ARTIFACTS_TOMLS =
    filter(isfile, [joinpath(REPO_ROOT, dir, "OutputArtifacts.toml") for dir in ARTIFACT_DIRS])

@testset verbose = true "ClimaArtifacts" begin
    include("readme_links.jl")
    include("output_artifacts.jl")
    include("unique_artifact_names.jl")
    include("manifests.jl")
    include("download_artifacts.jl")
end
