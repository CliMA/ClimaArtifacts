@testset "README.md links" begin
    readme = read(joinpath(REPO_ROOT, "README.md"), String)
    # Directories in the README.md
    linked_dirs = unique(
        String(m[1]) for
        m in eachmatch(r"github\.com/CliMA/ClimaArtifacts/tree/main/([^/)#\s]+)", readme)
    )

    @testset "Every artifact directory in the repository is listed in the README.md" begin
        @test isempty(setdiff(ARTIFACT_DIRS, linked_dirs))
    end

    @testset "Every directory in the README.md exists in the repository" begin
        @test isempty(setdiff(linked_dirs, readdir(REPO_ROOT)))
    end
end
