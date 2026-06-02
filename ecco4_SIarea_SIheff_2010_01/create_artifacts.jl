using ClimaArtifactsHelper
using DotEnv
using HTTP
using Base64

# URLs for ECCO data
url_SIarea = "https://ecco.jpl.nasa.gov/drive/files/Version4/Release4/interp_monthly/SIarea/2010/SIarea_2010_01.nc"
url_SIheff = "https://ecco.jpl.nasa.gov/drive/files/Version4/Release4/interp_monthly/SIheff/2010/SIheff_2010_01.nc"

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
username = ENV["ECCO_USERNAME"]
password = ENV["ECCO_WEBDAV_PASSWORD"]
credentials = base64encode("$username:$password")

# download data into artifact directory
artifact_dir = basename(@__DIR__) * "_artifact"
if isdir(artifact_dir)
    @warn "Artifact directory $artifact_dir already exists. Content will end up in the artifact and may be overwritten."
else
    @info "Creating artifact directory $artifact_dir"
    mkdir(artifact_dir)
end
headers = ["Authorization" => "Basic $credentials"]

response_SIarea = HTTP.get(url_SIarea, headers)
open("$artifact_dir/SIarea_2010_01.nc", "w") do f
    write(f, response_SIarea.body)
end
@info "Downloaded $artifact_dir/SIarea_2010_01.nc"

response_SIheff = HTTP.get(url_SIheff, headers)
open("$artifact_dir/SIheff_2010_01.nc", "w") do f
    write(f, response_SIheff.body)
end
@info "Downloaded $artifact_dir/SIheff_2010_01.nc"

# create artifact
create_artifact_guided(artifact_dir; artifact_name=basename(@__DIR__))

# ecco4_SIarea_SIheff_2010_01_artifact should now have the following files:
# - SIarea_2010_01.nc (2.1 MB)
# - SIheff_2010_01.nc (2.1 MB)
