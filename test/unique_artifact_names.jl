# Users copy entries from several directories into one Artifacts.toml, so names must not clash
@testset "Artifact names are unique" begin
    # Map each artifact name to the directories whose OutputArtifacts.toml
    # defines it
    directories_by_name = Dict{String, Vector{String}}()
    for toml_path in OUTPUT_ARTIFACTS_TOMLS
        directory = basename(dirname(toml_path))
        for name in keys(TOML.parsefile(toml_path))
            push!(get!(directories_by_name, name, String[]), directory)
        end
    end
    duplicates = Dict(name => dirs for (name, dirs) in directories_by_name if length(dirs) > 1)
    @test isempty(duplicates)
end
