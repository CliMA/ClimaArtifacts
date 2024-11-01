This artifact contains two datasets: one corresponding to a simulation solving Richards Equation in clay, and another solving it in sand. These experiments were conducted in Gordon Bonan's "Climate Change and Terrestrial Ecosystem Modeling" textbook, Chapter 8 supplementary program 1, using his Matlab code solving Richards Equation.

## Dataset Generation
The provided script `get_bonan_data.sh` acquires two datasets using Bonan's [Matlab code](https://github.com/gbonan/bonanmodeling); one for clay and one for sand. First, we need to clone the Github repository bonanmodeling. To generate the clay dataset, we run the script in `bonanmodeling/sp_08_01/sp_08_01.m` as-is, and the data is output to file `bonan_modeling/sp_08_01/data1.txt`. The first column of this text file contains the volumetric water content (theta) at the end of the simulation, and the second column contains the depth in the soil (z) corresponding to each value of theta.

To generate the sand dataset, we run the same script, but comment out lines 60-66 and uncomment lines 69-75. This changes the parameters from those for clay to those for sand, and the data will be output in the same filename and format that it was for the clay case.

The provided `get_bonan_data.sh` script does all of this, and renames both output data files to `bonan_richards_eqn_artifact/bonan_data_clay.txt` and `bonan_richards_eqn_artifact/bonan_data_sand.txt`, respectively.

#### Full citation:
Bonan, Gordon. Climate Change and Terrestrial Ecosystem Modeling. Cambridge University Press, 2019.
