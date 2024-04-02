module ClimaArtifactsHelper

using ArtifactUtils
using REPL.TerminalMenus
using Pkg.Artifacts

import SHA: sha1

export create_artifact_guided

const MB = 1024 * 1024

# Mark files larger than this as "undownloadable". This will prevent them from
# being mirrored by the Julia servers
const LARGE_FILESIZE = 500MB

"""
    foldersize(dir = ".")

Recursively walk dir and find the total size of all the files.
"""
function foldersize(dir = ".")
    size = 0
    for (root, dirs, files) in walkdir(dir)
        size += sum(map(filesize, joinpath.(root, files)))
    end
    return size
end

"""
    add_tar_gz_to_path(path)

Add the `tar.gz` extension to the given path (assumed to be a folder).

This function does not work on windows because it assumes the separator.
"""
function add_tar_gz_to_path(path)
    # Ensure path ends with a single slash, if any, and append ".tar.gz"
    return string(replace(path, r"/$" => ""), ".tar.gz")
end

"""
    create_tarball(artifact_dir)

Create a `tar.gz` from the given directory. Return the path.
"""
function create_tarball(
    artifact_dir;
    tar_path = add_tar_gz_to_path(artifact_dir),
)
    artifact_id = ArtifactUtils.artifact_from_directory(artifact_dir)
    ArtifactUtils.archive_artifact(artifact_id, tar_path)
    return tar_path
end

function _recommend_uploading_to_cluster(hash, artifact_name, artifact_dir)
    println("The id of your artifact is $hash")
    println(
        "Create the folder `/groups/esm/artifacts/$artifact_name` on the cluster",
    )
    println("Then, upload the content of $artifact_dir to that folder")
    println(
        "Add the following entry to the Overrides.toml file you find in `/groups/esm/ClimaArtifacts/artifacts/`",
    )
    println()
    println("$hash = \"/groups/esm/ClimaArtifacts/artifacts/$artifact_name\"")
    println()
end

function _create_downloadable_artifact(
    artifact_dir;
    artifact_name,
    output_artifacts = "OutputArtifacts.toml",
)
    println("First, we will create the artifact tarball")
    println(
        "You will upload it to the Caltech Data Archive and provide the direct link",
    )
    println("Archiving artifact (might take a while)")
    tar_path = create_tarball(artifact_dir)

    println("Artifact archived!")

    println(
        "Now, upload $tar_path to the Caltech Data Archive or Box, paste here the link, and press ENTER",
    )
    println(
        "If you upload it to Box, make it visible and share the static link",
    )
    print("> ")
    tarball_url = readline()

    println(
        "I will try to download your freshly minted artifact to check that it works (might take a while)",
    )

    # Bind the artifact to a temporary Artifact.toml, retrieve it, and print it.
    # We crate a temporary Artifact.toml to ensure that it is an empty file.
    mktempdir() do path
        artifact_toml = joinpath(path, "Artifacts.toml")
        hash = ArtifactUtils.add_artifact!(
            artifact_toml,
            artifact_name,
            tarball_url,
        )
        open(artifact_toml, "r") do file
            artifact_str = read(file, String)
            println(
                "Here is your artifact string. Copy and past it to your Artifacts.toml",
            )
            println()
            println(artifact_str)
        end
        Base.mv(artifact_toml, output_artifacts, force = true)
        println("You should also consider uploading your data to the cluster")
        _recommend_uploading_to_cluster(hash, artifact_name, artifact_dir)
    end
end

"""
    create_artifact_guided(artifact_dir)

Start a guided process to create an artifact from a directory of files.
"""
function create_artifact_guided(artifact_dir; artifact_name)
    output_artifacts = "OutputArtifacts.toml"
    # This is where we save the string we create
    isfile(output_artifacts) &&
        @warn "Found $output_artifacts. It will be overwritten"

    if foldersize(artifact_dir) > LARGE_FILESIZE
        # Artifacts that are too large. In this case, we have to manually create an hash and
        # recommend using the Overrides.toml
        println(
            "The artifact directory is large ($(foldersize(artifact_dir)) bytes), so the artifact has to be handled manually",
        )

        # We use the name to create the hash
        hash = bytes2hex(sha1(artifact_name))

        _recommend_uploading_to_cluster(hash, artifact_name, artifact_dir)
        println(
            "Here is your artifact string. Copy and past it to your Artifacts.toml",
        )
        println()
        artifacts_str = "[$artifact_name]\ngit-tree-sha1 = \"$hash\"\n"
        println(artifacts_str)

        open(output_artifacts, "w") do file
            write(file, artifacts_str)
        end
    else
        _create_downloadable_artifact(
            artifact_dir;
            artifact_name,
            output_artifacts,
        )
    end

    println("Artifact string saved to $output_artifacts")
    println("Feel free to add other metadata/properties (e.g., laziness)")
    println("Enjoy the rest of your day!")
end

end
