module ClimaArtifactsHelper

using ArtifactUtils
using REPL.TerminalMenus

using Pkg.Artifacts

export create_add_artifact_guided

const MB = 1024 * 1024 * 1024

# Mark files larger than this as "undownloadable". This will prevent them from
# being mirrored by the Julia servers
const LARGE_FILESIZE = 500MB

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

"""
    create_add_artifact_guided(artifact_dir)

Start a guided process to create an artifact from a directory of files.
"""
function create_add_artifact_guided(artifact_dir; artifact_name)
    undownloadable = false
    if filesize(artifact_dir) > LARGE_FILESIZE
        undownloadable = true
        error("NOT IMPLEMENTED YET")
        # TODO: Implement this feature
    end

    println("First, we will create the artifact tarball")
    println(
        "You will upload it to the Caltech Data Archive and provide the direct link",
    )
    println("Archiving artifact (might take a while)")
    tar_path = create_tarball(artifact_dir)

    println("Artifact archived!")

    println(
        "Now, upload $tar_path to the Caltech Data Archive, paste here the link, and press ENTER",
    )
    print("> ")
    tarball_url = readline()

    println(
        "I will try to download your freshly minted artifact to check that it works (might take a while)",
    )

    # Bind the artifact, retrieve the Artifact.toml, and print it
    mktempdir() do path
        artifact_toml = joinpath(path, "Artifacts.toml")
        ArtifactUtils.add_artifact!(artifact_toml, artifact_name, tarball_url)
        open(artifact_toml, "r") do file
            artifact_str = read(file, String)
            println(
                "Here is your artifact string. Copy and past it to your Artifacts.toml",
            )
            println()
            println(artifact_str)
        end
    end

    println("Feel free to add other metadata and make it lazy")
    println("Enjoy the rest of your day!")
end

end
