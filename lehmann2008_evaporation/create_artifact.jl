# Note: Since this dataset was acquired from the authors, we do not have a script to recreate it.
# This script is only used to create the artifact from the dataset direct download link.
using ClimaArtifactsHelper

const FILE_URL = "https://caltech.box.com/shared/static/cgppw3tx6zdz7h02yt28ri44g1j088ju.csv"
const FILE_PATH = "lehmann2008_fig8_evaporation.csv"

create_artifact_guided_one_file(FILE_PATH; artifact_name = basename(@__DIR__), file_url = FILE_URL)
