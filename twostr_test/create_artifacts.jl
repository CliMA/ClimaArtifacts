# This script generates test data for the CliMALand TwoStream radiative transfer
# model. The data is generated from an earlier TwoStream implementation,
# PySellersTwoStream:
# Quaife, T. 2016: PySellersTwoStream, available at:
# https://github.com/tquaife/pySellersTwoStream.
# We use a fork of the repository which has been patched to work with Python 3.

# This package does not allow for a clumping index while the ClimaLand
# implementation does. All other parameters used to generate the test data
# correspond to parameters in the ClimaLand implementation. The output data
# is a CSV file with each row corresponding to a test case. The columns are
# the parameters: solar zenith angle, leaf area index, leaf/stem orientation
# index, leaf reflectance, leaf transmittance, soil albedo, the number of layers
# in the canopy, and the proportion of incident radiation which is diffuse. Then
# there is an output column for the fraction of absorbed photosynthetically
# active radiation (fAPAR).

################################################################################
# IMPORTS                                                                      #
################################################################################

using ClimaArtifactsHelper
import LibGit2

################################################################################
# CONSTANTS                                                                    #
################################################################################

# Output directory
OUTPUT_DIR = "twostr_test"

# Output file name
OUTPUT_FILE = "twostr_test.csv"

# Path used to clone PySellersTwoStream repository
PSTS_PATH = "https://github.com/Espeer5/py3SellersTwoStream"

################################################################################
# MAIN                                                                         #
################################################################################

if isdir(OUTPUT_DIR)
    @warn "$OUTPUT_DIR already exists. Content will end up in the artifact and
           may be overwritten."
    @warn "Abort this calculation, unless you know what you are doing."
else
    mkdir(OUTPUT_DIR)
end

# First, git clone the PySellersTwoStream repository from the PSTS_PATH
isdir("py3SellersTwoStream") || LibGit2.clone(PSTS_PATH, "py3SellersTwoStream")

# Next, run the python script that generates the output test data
run(`python3 gen_2str_data.py $OUTPUT_DIR/$OUTPUT_FILE`)

# Now, use guided artifact creation to create the artifact
create_artifact_guided(OUTPUT_DIR; artifact_name = basename(@__DIR__))
