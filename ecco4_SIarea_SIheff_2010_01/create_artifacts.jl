using ClimaArtifactsHelper
import ClimaOcean as CO
using Dates
using DotEnv
import SHA: sha1

# ECCO requires authentication
DotEnv.load!()
if !("ECCO_USERNAME" in keys(ENV)) || !("ECCO_WEBDAV_PASSWORD" in keys(ENV))
    error(
        """
        Before running this script, you must create a `.env` file with the following content:

        ECCO_USERNAME=your_ecco_username
        ECCO_WEBDAV_PASSWORD=your_ecco_webdav_password
        """,
    )
end

# for this artifact, we just want the means over the month of January, 2010
date = Date(2010, 1, 1)

# use ClimaOcean DataWrangling to get the metadata
sic_metadata = CO.DataWrangling.Metadatum(
    :sea_ice_concentration,
    dataset = CO.DataWrangling.ECCO.ECCO4Monthly(),
    date = date,
)
sit_metadata = CO.DataWrangling.Metadatum(
    :sea_ice_thickness,
    dataset = CO.DataWrangling.ECCO.ECCO4Monthly(),
    date = date,
)

# download
CO.DataWrangling.ECCO.download_dataset(sic_metadata)
CO.DataWrangling.ECCO.download_dataset(sit_metadata)

# data paths (these should be in your ~/.julia/scratchspaces)
sic_path = CO.DataWrangling.metadata_path(sic_metadata)
sit_path = CO.DataWrangling.metadata_path(sit_metadata)

# move data to artifact directory
artifact_dir = basename(@__DIR__) * "_artifact"
if isdir(artifact_dir)
    @warn "$artifact_dir already exists. Content will end up in the artifact and may be overwritten."
    @warn "Abort this calculation, unless you know what you are doing."
else
    mkdir(artifact_dir)
end
Base.cp(sic_path, joinpath(artifact_dir, "ecco4_SIarea_2010_01.nc"), force = true)
Base.cp(sit_path, joinpath(artifact_dir, "ecco4_SIheff_2010_01.nc"), force = true)
@info "Data files copied to $artifact_dir"

# since ECCO data requires credentials, we'll make this an undownloadable artifact

# get hash
artifact_name = basename(@__DIR__)
hash = bytes2hex(sha1(artifact_name))

# print artifact string and cluster recommendations
ClimaArtifactsHelper._recommend_uploading_to_cluster(hash, artifact_name, artifact_dir)
println("Here is your artifact string. Copy and paste it to your Artifacts.toml")
println()
artifacts_str = "[$artifact_name]\ngit-tree-sha1 = \"$hash\"\n"
println(artifacts_str)

# save artifact string
output_artifacts = "OutputArtifacts.toml"
open_mode = "w"
open(output_artifacts, open_mode) do file
    write(file, artifacts_str)
end

# ecco4_SIarea_SIheff_2010_01_artifact should now have the following files:
# - ecco4_SIarea_2010_01.nc (2.1 MB)
# - ecco4_SIheff_2010_01.nc (2.1 MB)
