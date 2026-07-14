using ClimaArtifactsHelper
using Downloads
using ZipFile

# NFS woes... see Issue #177
pushfirst!(DEPOT_PATH, mktempdir(; prefix = "clima_artifacts_depot_"))

# URL for EN4 data
url = "http://www.metoffice.gov.uk/hadobs/en4/data/en4-2-1/EN.4.2.2/EN.4.2.2.analyses.g10.2010.zip"

# download data into artifact directory
artifact_dir = basename(@__DIR__) * "_artifact"
if isdir(artifact_dir)
    @warn "Artifact directory $artifact_dir already exists. Content will end up in the artifact and may be overwritten."
else
    @info "Creating artifact directory $artifact_dir"
    mkdir(artifact_dir)
end
zipfile_path = joinpath(artifact_dir, "EN.4.2.2.analyses.g10.2010.zip")
Downloads.download(url, zipfile_path)
@info "Downloaded $zipfile_path"

# unzip
zarchive = ZipFile.Reader(zipfile_path)
for f in zarchive.files
    if f.name == "EN.4.2.2.f.analysis.g10.201001.nc" # only extract the January 2010 file
        filepath = joinpath(artifact_dir, f.name)
        write(filepath, read(f))
        @info "Extracted $f.name to $filepath"
    end
end
close(zarchive)

# remove zip file
rm(zipfile_path)

# create artifact
create_artifact_guided(artifact_dir; artifact_name=basename(@__DIR__))

# en4_temperature_salinity_2010_01_artifact should now have the following file:
#   EN.4.2.2.f.analysis.g10.201001.nc (26 MB)
