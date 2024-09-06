using Downloads

using ClimaArtifactsHelper

const FILE_URL = "https://caltech.box.com/shared/static/j0kxdt9nxnk915burnwqs622ots2ylgv.nc"
const FILE_PATH = "CERES_EBAF_Ed4.2_Subset_200003-201910.nc"

create_artifact_guided_one_file(FILE_PATH; artifact_name = basename(@__DIR__), file_url = FILE_URL)
