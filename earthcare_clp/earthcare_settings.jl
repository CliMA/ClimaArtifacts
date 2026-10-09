# Settings shared by download.jl and create_artifact.jl.
import Dates

# Directory holding the ACM_CLP .h5 granules.
const GRANULE_DIR = "/net/sampo/data1/oalcabes/earthcare_data/ACM_CLP_data"

# Directory for monthly/ and the artifact folder.
const OUTPUT_DIR = @__DIR__

# Granule start times to use, from START_DATE up to but not including END_DATE.
# December 2025 to April 2026: the full JXBA months in GRANULE_DIR. Granules
# there start on 2025-12-05. May 2026 has JXBA granules on only eight days.
const START_DATE = Dates.DateTime(2025, 12, 1)
const END_DATE = Dates.DateTime(2026, 5, 1)

# Processing baseline to keep. Empty string for all.
const BASELINE = "JXBA"
