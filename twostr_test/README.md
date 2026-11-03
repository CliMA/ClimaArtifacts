# TwoStream radiative transfer model test cases

This artifact contains test cases mapping sets of input parameters to expected output values for the TwoStream radiative transfer model. The test cases are used to validate the implementation of the TwoStream model in ClimaLand.

The create_artifacts script hosted here generates a csv file with test cases for the TwoStream model compared against the outputs of a previous implementation of the TwoStream model:

Quaife, T. 2016: PySellersTwoStream, available at:
https://github.com/tquaife/pySellersTwoStream.

We use a fork of the repository which has been patched to work with Python 3.

The code used to generate this test data is licensed under GPL 2.0; the data
itself is generated from this code and therefore we will also license it under
GPL 2.0.

## Creating the artifact

Run the following commands in this directory (tested with Python 3.12):

```
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
julia +1.11 --project -e 'using Pkg; Pkg.instantiate()'
julia +1.11 --project create_artifacts.jl
```
