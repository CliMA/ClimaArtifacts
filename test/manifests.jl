# Artifacts created without a manifest and tests are added afterward
# TODO: Add manifests for these artifacts
const DIRECTORIES_WITHOUT_MANIFEST = [
    "atmos_dyamond_summer",
    "cfsite_gcm_forcing",
    "era5_land_forcing_data2008",
    "fluxnet_sites",
    "ilamb_data",
    "modis_lai",
    "soilgrids",
    "topmodel",
    "wxquest_initial_conditions",
]

@testset "Manifest.toml" begin
    missing_manifest =
        filter(dir -> "Manifest.toml" ∉ readdir(joinpath(REPO_ROOT, dir)), ARTIFACT_DIRS)

    @testset "Every artifact directory has a Manifest.toml" begin
        @test isempty(setdiff(missing_manifest, DIRECTORIES_WITHOUT_MANIFEST))
    end

    @testset "DIRECTORIES_WITHOUT_MANIFEST only lists directories without one" begin
        @test isempty(setdiff(DIRECTORIES_WITHOUT_MANIFEST, missing_manifest))
    end
end
