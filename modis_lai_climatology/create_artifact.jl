# MODIS LAI Monthly Climatology
#
# This artifact creates a monthly climatology from the yearly MODIS LAI files
# in the modis_lai artifact by averaging across years (2000-2020).
#
# The climatology uses uniform 30-day spacing for compatibility with
# ClimaLand's PeriodicCalendar boundary condition.

################################################################################
# IMPORTS                                                                      #
################################################################################

using ClimaArtifactsHelper
using Artifacts

################################################################################
# CONSTANTS                                                                    #
################################################################################

# Output directory (will become the artifact)
OUTPUT_DIR = "modis_lai_climatology"

# Output file name
OUTPUT_FILE = "modis_lai_climatology.nc"

################################################################################
# MAIN                                                                         #
################################################################################

if isdir(OUTPUT_DIR)
    @warn "$OUTPUT_DIR already exists. Content will end up in the artifact and may be overwritten."
    @warn "Abort this calculation, unless you know what you are doing."
else
    mkdir(OUTPUT_DIR)
end

# Get path to modis_lai artifact (the source data)
modis_lai_path = artifact"modis_lai"

# Output path for the climatology
output_path = joinpath(OUTPUT_DIR, OUTPUT_FILE)

# Run the Python script to generate the climatology
# The script requires: xarray, numpy, pandas, matplotlib, netCDF4
python_script = joinpath(@__DIR__, "get_modis_climatology.py")

cmd = `python3 $python_script --input-dir $modis_lai_path --output $output_path`
@info "Running: $cmd"
run(cmd)

# Verify output was created
if !isfile(output_path)
    error("Failed to create climatology file: $output_path")
end

@info "Successfully created climatology at $output_path"

# Create the artifact
create_artifact_guided(OUTPUT_DIR; artifact_name = basename(@__DIR__))
