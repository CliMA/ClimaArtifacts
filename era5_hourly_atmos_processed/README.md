# Processed ERA5 Hourly Forcing Data for ClimaAtmos

This artifact stores the raw ERA5 data used by ClimaAtmos to produce
time varying forcing data.

Running `create_artifact.jl` will create the artifact with some sample data for July 2007 at 17 degrees latitude and -149 degrees longitude. If users need data for a time and location not available in the sample data, ClimaAtmos will use data from the `era5_hourly_atmos_raw` artifact to add a processed file to this artifact, or
they can use Overrides.toml to point to a folder containing the needed data.

The processed files are expected to follow the following naming scheme:

_sim_forcing_loc_(lat)_(lon)_(date).nc

For example, the sample data file is named `tv_forcing_17.0_-149.0_20070701.nc`.
