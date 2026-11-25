using Downloads
using TOML
using ClimaArtifactsHelper

# Pre-computed orographic gravity wave (OGW) topographic drag tensor fields at different horizontal
# resolutions (h_elem). Each HDF5 file contains the drag tensor (t11, t12,
# t21, t22) and mountain height fields (hmax, hmin) computed from raw
# topography on the ClimaAtmos cubed-sphere grid.
#
# Source: Garner (2005), "A Topographic Drag Closure Built on an Analytical
# Base Flux", J. Atmos. Sci., 62, 2302-2315.

artifacts = [
    (4, "https://caltech.box.com/shared/static/2lwn4qcnag1xlz7ggrgn27zzwxbyb53h.hdf5"),
    (6, "https://caltech.box.com/shared/static/a3izc3vd7zmjrrp6hbe1e01ilcioyh9n.hdf5"),
    (8, "https://caltech.box.com/shared/static/f1pwqwvee0ewm4i9kcyqdrx2lj6rsgpz.hdf5"),
    (12, "https://caltech.box.com/shared/static/sq5l8rb4pldvmik4mw3ty9zl32960osa.hdf5"),
    (16, "https://caltech.box.com/shared/static/m842l5uaa3wzz0e6sk6q00jlancbgram.hdf5"),
    (30, "https://caltech.box.com/shared/static/lkwl4g99rjqdnofyep8vwo5odqn0tp3y.hdf5"),
    (60, "https://caltech.box.com/shared/static/dtajt8lpjrvdpp3lmbs35mgf1cm5xxuf.hdf5"),
]

existing_artifacts = if isfile("OutputArtifacts.toml")
    TOML.parsefile("OutputArtifacts.toml")
else
    Dict{String, Any}()
end
first_new = true

for (i, (h_elem, file_url)) in enumerate(artifacts)
    artifact_name = "ogw_computed_drag_h$(h_elem)"

    if haskey(existing_artifacts, artifact_name)
        print("$artifact_name already exists in OutputArtifacts.toml. Overwrite? (y/n): ")
        answer = strip(readline())
        if lowercase(answer) != "y"
            @info "Skipping $artifact_name"
            continue
        end
    end

    file_path = "computed_drag_Earth_false_1_$(h_elem).hdf5"
    output_dir = artifact_name * "_artifact"

    # Create output directory
    if isdir(output_dir)
        @warn "$output_dir already exists. Content will end up in the artifact and may be overwritten."
        @warn "Abort this calculation, unless you know what you are doing."
    else
        mkdir(output_dir)
    end

    # Download file if not present
    if !isfile(file_path)
        @info "$file_path not found, downloading it (might take a while)"
        downloaded_file = Downloads.download(file_url; progress = download_rate_callback())
        Base.mv(downloaded_file, file_path)
    end

    # Copy file to output directory
    target_path = joinpath(output_dir, basename(file_path))
    if !isfile(target_path)
        Base.cp(file_path, target_path)
    else
        @info "$target_path already exists, skipping copy"
    end

    # Create artifact (append unless this is the first entry in the file)
    append = !(first_new && isempty(existing_artifacts))
    create_artifact_guided(output_dir; artifact_name = artifact_name, append)
    global first_new = false
end

@info "Generated OGW computed drag artifacts"
