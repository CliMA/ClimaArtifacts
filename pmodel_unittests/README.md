This artifact contains unit test data (inputs and expected outputs) for the P-model, a model for photosynthesis and stomatal conductance used in ClimaLand. 

`create_artifact.jl` downloads two CSV data files required for P-model unit testing from Caltech Box. These files contain reference data and expected outputs that are used to validate the P-model implementation. These data were generated using [Rpmodel](https://github.com/geco-bern/rpmodel), an implementation of the P model in R. To generate this data from scratch, download the Rpmodel package in R according to these [instructions](https://github.com/geco-bern/rpmodel), then run the script `pmodel_test.r`.

Stocker, B. D., Wang, H., Smith, N. G., Harrison, S. P., Keenan, T. F., Sandoval, D., ... & Prentice, I. C. (2020). P-model v1. 0: An optimality-based light use efficiency model for simulating ecosystem gross primary production. *Geoscientific Model Development*, 13(3), 1545-1581.
