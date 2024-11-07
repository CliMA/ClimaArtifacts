"""
This script is used to generate test cases for the ClimaLand TwoStream model
implementation. The script generates a csv file with test cases for the
TwoStream model compared against the outputs of a previous implementation of the
TwoStream model:
Quaife, T. 2016: PySellersTwoStream, available at:
https://github.com/tquaife/pySellersTwoStream.
We use a fork of the repository which has been patched to work with Python 3.

This package does not allow for a clumping index while the ClimaLand
implementation does. All other parameters used to generate the test data
correspond to parameters in the ClimaLand implementation. The output data is a
CSV file with each row corresponding to a test case. The columns are the 
parameters: solar zenith angle, leaf area index, leaf/stem orientation index,
leaf reflectance, leaf transmittance, soil albedo, the number of layers in the
canopy, and the proportion of incident radiation which is diffuse. Then there is
an output column for the fraction of absorbed photosynthetically active
radiation (fAPAR).
"""

################################################################################
# IMPORTS                                                                      #
################################################################################

import csv
import sys
from numpy import arange

# Append the path to the sellersTwoStream package to python path
sys.path.append("./py3SellersTwoStream")

from sellersTwoStream import twoStream

################################################################################
# CONSTANTS                                                                    #
################################################################################

# Ranges to generate data over
mu_range    = (0.1, 1)
ld_range    = (0.1, 0.3)
rho_range   = (0.1, 0.3)
tau_range   = (0.1, 0.3)
alb_range   = (0.1, 0.3)
diff_range  = (0, 1)
layer_range = (1, 5)
LAI_range   = (3, 6)

# columns to create in csv
columns = ["mu", "LAI", "ld", "rho", "tau", "a_soil", "n_layers",
           "prop_diffuse", "FAPAR"]

################################################################################
# MAIN                                                                         #
################################################################################

if __name__ == "__main__":
    # Ensure the output file location was passed to the script
    if len(sys.argv) != 2:
        print("Usage: python gen_2str_data.py <output_file>")
        sys.exit(1)

    # Read the output file name from the command line
    DATA_FILE = sys.argv[1]

    # Create a TwoStream model
    T = twoStream()
    # For every combination of input parameters, calculate the fAPAR and write
    # the input parameters and output fAPAR to csv file
    with open(DATA_FILE, 'w') as out:
        writer = csv.DictWriter(out, fieldnames=columns)
        writer.writeheader()
        for n in range(layer_range[0], layer_range[1]):
            for prop in arange(diff_range[0], diff_range[1], 0.2):
                for alb in arange(alb_range[0], alb_range[1], 0.1):
                    for tau in arange(tau_range[0], tau_range[1], 0.1):
                        for rho in arange(rho_range[0], rho_range[1], 0.1):
                            for ld in arange(ld_range[0], ld_range[1], 0.1):
                                for mu in arange(mu_range[0], mu_range[1], 0.2):
                                    for LAI in arange(LAI_range[0],
                                                      LAI_range[1], 1):
                                        T.mu = mu
                                        T.propDif = prop
                                        T.lai = LAI
                                        T.leaf_r = rho
                                        T.leaf_t = tau
                                        T.soil_r = alb
                                        T.nLayers = n
                                        T.G = lambda _ : ld
                                        T.Z = lambda _ : 1
                                        K = T.K_generic()
                                        T.K = lambda: K
                                        MB = T.muBar_generic()
                                        T.muBar = lambda: MB
                                        B_dir = \
                                              T.B_direct_Dickinson_generic_ssa()
                                        T.B_direct = lambda: B_dir
                                        B_diff = T.B_diffuse_generic()
                                        T.B_diffuse = lambda: B_diff
                                        IupPAR, IdnPAR, IabPAR, Iab_dLaiPAR = \
                                                                   T.getFluxes()
                                        FAPAR = sum(IabPAR)
                                        row = {
                                            "mu":mu,
                                            "LAI":LAI,
                                            "ld":ld,
                                            "rho":rho,
                                            "tau":tau,
                                            "a_soil":alb,
                                            "n_layers":n,
                                            "prop_diffuse":prop,
                                            "FAPAR": FAPAR
                                        }
                                        writer.writerow(row)
