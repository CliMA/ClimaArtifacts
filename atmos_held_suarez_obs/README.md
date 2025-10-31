# Air Temperature Data Generated from ClimaAtmos v0.24.0

## Overview

This artifact contains the observational data and restart file needed to reproduce a ClimaAtmos perfect model calibration. The observational data consists of a sample from 60-day zonal averages of air temperature at 242m altitude.

To produce the data, ClimaAtmos is run with a spherical moist Held-Suarez configuration for 3000days, saving 60-day averages air temperature values and a restart/checkpoint file at 200 days.
The diagnostic temperature output is processed by taking zonally-averaged values at 242m altitude, producing one observation every 60 days. The variance of all observations and the sample value taken at 240 days are used in the calibration.

To recreate this data, run the model with the script `run_model.jl`. Since this will run ClimaAtmos for 3000days, it is advisable to use Slurm.
This will work on the Resnick HPC:

```bash
#!/bin/bash
#SBATCH --time=3:00:00
#SBATCH --ntasks=32
#SBATCH --partition=expansion
#SBATCH --output="model_log.txt"
export MODULEPATH=/resnick/groups/esm/modules:$MODULEPATH
module load climacommon/2024_04_30

srun julia --project=. run_model.jl
```

Then, to recreate the artifact, run `julia --project=. create_artifact.jl`

## File Summary

- `day200.0.hdf5`: The steady-state restart file, obtained by running the model for 200 days.
- `obs_mean.jld2`: Float64-valued 1-length vector storing the time and zonally averaged temperature taken by running the model for 3000 days. JLD2 format.
- `obs_noise_cov.jld2`: Float64-valued 1x1 matrix for the observational data storing the covariance matrix of the full observations. JLD2 format.
- `model_config.yml`: The model configuration used in the perfect model experiment
