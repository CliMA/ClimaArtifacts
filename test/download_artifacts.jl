# Artifacts whose file on Box no longer matches their OutputArtifacts.toml
# TODO: Fix this
const BROKEN_ARTIFACTS = ["optimal_lai_inputs", "soil_ic_2008_50m"]

"""
    download_from_url(tree_hash, url, sha256)

Download and unpack the artifact at `url` into a fresh temporary artifacts directory,
verifying the tarball's `sha256` and the unpacked `tree_hash`. Return `true` on success
and the error otherwise.

`Pkg.Artifacts.download_artifact` only fetches from `url`, unlike
`ensure_artifact_installed`, which first tries the Pkg server. The isolated artifacts
directory prevents a cached copy from passing the check without downloading.
"""
function download_from_url(tree_hash, url, sha256)
    return mktempdir() do dir
        Pkg.Artifacts.with_artifacts_directory(dir) do
            Pkg.Artifacts.download_artifact(tree_hash, url, sha256; quiet_download = true)
        end
    end
end

# verbose shows every download in the summary, not only failing ones
@testset verbose = true "Downloads" begin
    toml_paths = if isempty(ARGS)
        OUTPUT_ARTIFACTS_TOMLS
    else
        [joinpath(abspath(dir), "OutputArtifacts.toml") for dir in ARGS]
    end
    artifacts = [
        artifact for toml_path in toml_paths for
        artifact in TOML.parsefile(toml_path) if haskey(last(artifact), "download")
    ]
    @testset "$name" for (name, meta) in sort!(artifacts; by = first)
        tree_hash = Base.SHA1(meta["git-tree-sha1"])
        for entry in meta["download"]
            result = download_from_url(tree_hash, entry["url"], entry["sha256"])
            @test result === true broken = name in BROKEN_ARTIFACTS
        end
    end
end
