using ClimaArtifactsHelper

const FILE_URL = "https://swift.dkrz.de/v1/dkrz_ab6243f85fe24767bb1508712d1eb504/SAPPHIRE/DYAMOND/ifs_oper_T1279_2016080100.nc"
const FILE_PATH = "ifs_oper_T1279_2016080100.nc"

artifact_name = "DYAMOND_summer_initial_conditions"

create_artifact_guided_one_file(FILE_PATH; artifact_name = artifact_name, file_url = FILE_URL)
