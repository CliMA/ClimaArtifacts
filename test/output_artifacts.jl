@testset "Every artifact directory has an OutputArtifacts.toml" begin
    missing_toml =
        filter(dir -> "OutputArtifacts.toml" ∉ readdir(joinpath(REPO_ROOT, dir)), ARTIFACT_DIRS)
    @test isempty(missing_toml)
end
