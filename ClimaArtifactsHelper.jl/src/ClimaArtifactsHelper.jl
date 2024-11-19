module ClimaArtifactsHelper

using ArtifactUtils
using REPL.TerminalMenus
using Pkg.Artifacts

import SHA: sha1
import Downloads: download

export create_artifact_guided,
    create_artifact_guided_one_file,
    download_rate_callback

const MB = 1024 * 1024
const GB = 1024 * MB

# Mark files larger than this as "undownloadable". This will prevent them from
# being mirrored by the Julia servers
const LARGE_FILESIZE = 500MB

"""
    download_size_string(bytes)

Return a human-readable string for the given number of bytes.
"""
function download_size_string(bytes)
    if bytes >= GB
        size = round(bytes/GB, digits=2)
        unit = "GB"
    else
        size = div(bytes, MB)
        unit = "MB"
    end
    return "$size $unit"
end

"""
    download_rate_callback()

Create a callback that prints the download rate to the terminal. The returned function is
designed to be used as a callback for Downloads.jl.
"""
function download_rate_callback()
    last_time::Float64 = time()
    last_now::Int = 0
    return (total, now) -> begin
        now_time = time()
        if now_time - last_time > 1
            download_rate = round(Int, (now - last_now) / (now_time - last_time))
            if total == 0
                print("Downloaded $(download_size_string(now)) ")
            else
                print(
                    "Downloaded $(download_size_string(now)) out of $(download_size_string(total)): "
                )
                print("$(div(now * 100, total))% complete ")
            end
            print("at download rate of: $(download_size_string(download_rate))/s\r")
            last_time = now_time
            last_now = now
        end
    end
end

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
        "Create the folder `/groups/esm/ClimaArtifacts/artifacts/$artifact_name` on the cluster",
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
    append = false
)
    open_mode = append ? "a" : "w"

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
                "Here is your artifact string. Copy and paste it to your Artifacts.toml",
            )
            println()
            println(artifact_str)
        end
        open(output_artifacts, open_mode) do file
            write(file, read(artifact_toml))
        end
        println("You should also consider uploading your data to the cluster")
        _recommend_uploading_to_cluster(hash, artifact_name, artifact_dir)
    end
end

"""
    create_artifact_guided(artifact_dir)

Start a guided process to create an artifact from a directory of files.

When the `append` flag is set to `true`, append the new artifact string to
the existing `OutputArtifacts.toml` file.
"""
function create_artifact_guided(artifact_dir; artifact_name, append = false)
    output_artifacts = "OutputArtifacts.toml"
    open_mode = append ? "a" : "w"

    # This is where we save the string we create
    append || (isfile(output_artifacts) && @warn "Found $output_artifacts. It will be overwritten")

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
            "Here is your artifact string. Copy and paste it to your Artifacts.toml",
        )
        println()
        artifacts_str = "[$artifact_name]\ngit-tree-sha1 = \"$hash\"\n"
        println(artifacts_str)

        open(output_artifacts, open_mode) do file
            write(file, artifacts_str)
        end
    else
        _create_downloadable_artifact(
            artifact_dir;
            artifact_name,
            output_artifacts,
            append
        )
    end

    println("Artifact string saved to $output_artifacts")
    println("Feel free to add other metadata/properties (e.g., laziness)")
    println("Enjoy the rest of your day!")
end

"""
    create_artifact_guided_one_file(file_path; artifact_name, file_url)

Start a guided process to create an artifact from one file.

If the file is not present at `file_path`, it will be downloaded from `file_url`.

When the `append` flag is set to `true`, append the new artifact string to
the existing `OutputArtifacts.toml` file.
"""
function create_artifact_guided_one_file(
    file_path;
    artifact_name,
    file_url = nothing,
    append = false
)
    output_dir = artifact_name

    if isdir(output_dir)
        @warn "$output_dir already exists. Content will end up in the artifact and may be overwritten."
        @warn "Abort this calculation, unless you know what you are doing."
    else
        mkdir(output_dir)
    end

    if !isfile(file_path)
        isnothing(file_url) && error("File not found but file url not provided")
        @info "$file_path not found, downloading it (might take a while)"
        downloaded_file = download(file_url; progress = download_rate_callback())
        Base.mv(downloaded_file, file_path)
    end
    # There are issues with large files in Base.cp https://github.com/JuliaLang/julia/issues/56537
    if Sys.iswindows()
        Base.cp(file_path, joinpath(output_dir, basename(file_path)))
    else
        run(`cp $file_path $(joinpath(output_dir, basename(file_path)))`)
    end

    create_artifact_guided(output_dir; artifact_name, append)
end

end
