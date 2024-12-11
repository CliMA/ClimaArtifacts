# Water conservation test dataset

This dataset is used as a reference solution for a particular setup of the
ClimaLand.jl soil water model (`RichardsModel`). It was created by running
the `water_conservation.jl` experiment with an explicit solver and a very
small timestep. To recreate it, we need to check out a commit of ClimaLand.jl
where this type of model was stepped fully explicitly; it has since been changed
to be stepped with a mixed implicit/explicit algorithm.

Note that if the physics implemented in `RichardsModel` changes, this dataset
will need to be regenerated so it can still be used as a comparison for the
current code.
