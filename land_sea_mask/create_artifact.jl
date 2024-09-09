using Downloads

using ClimaArtifactsHelper

# Downloaded from https://www.ncl.ucar.edu/Applications/Data/#cdf
const FILE_URL = "https://www.ncl.ucar.edu/Applications/Data/cdf/landsea.nc"
const FILE_PATH = "landsea.nc"

create_artifact_guided_one_file(FILE_PATH; artifact_name = basename(@__DIR__), file_url = FILE_URL)
@info "Land-sea mask file generated!"
