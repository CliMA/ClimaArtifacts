# Raw ERA5 Hourly Forcing Data for ClimaAtmos

This artifact stores the raw ERA5 data used by ClimaAtmos to produce
time varying forcing data.

Running `create_artifact.jl` will create the artifact with some sample data for July 2007. If users need data for a time and location not available in the sample data, they should either add the needed data files into the artifact folder, or use
Overrides.toml to point to a folder containing the needed data.

Each month requires three data files with the following naming scheme:

1. hourly_accum_(date).nc
2. hourly_inst_(date).nc
3. forcing_and_cloud_hourly_profiles_(date).nc

For example, the sample data contains the files:

1. hourly_accum.nc
2. hourly_inst.nc
3. forcing_and_cloud_hourly_profiles.nc

## Requirements

- 9.8 GB of free disk storage

## Citation
