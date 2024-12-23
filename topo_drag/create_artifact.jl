using Downloads
using ClimaArtifactsHelper

const FILE_URL = "https://caltech.box.com/shared/static/isa7l4ow4xvv9vs09bivdwttbnnw5tte.nc"
const FILE_PATH = "topo_drag.res.nc"

create_artifact_guided_one_file(FILE_PATH; artifact_name = basename(@__DIR__), file_url = FILE_URL)
