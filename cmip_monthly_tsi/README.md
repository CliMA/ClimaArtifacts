# Total Solar irradiance, monthly means from 1850 to 2299

This artifact repackages data coming from the [CMIP7 solar forcing
datasets](https://www.solarisheppa.kit.edu/75.php) to a CSV file that contains
monthly averages of solar irradiance from 1850–2299. This is formed by
combining the reference solar forcing dataset (1850–2023) intended for
transient simulations and the future solar forcing dataset (2022–2299)
intended for future simulations.

## Prerequisites
1. Julia
2. `gzip`, a command-line utility for compression and decompression.

## Usage
To recreate this artifact:
1. Clone this repository and navigate to this directory.
2. Run `julia --project=. -e 'using Pkg; Pkg.instantiate(;verbose=true)'`
2. Run `julia --project=. create_artifact.jl`.

## Preprocessing

This artifact is a CSV file that contains the monthly averages of solar
irradiance (`tsi`) from 1850 to 2299. This is done by concatenating the
reference solar forcing dataset from 1850 to 2023 and the future solar forcing
dataset from 2024 to 2299. The years 2022 to 2024 from the future solar forcing
data is not included in this artifact.

There are two columns in the dataset, which are Date and Total Solar Irradiance.
The dates are always on the 15th day at 12:00 of the respective month in the CSV
file. The units of the total solar irradiance are `W m^-2` and the calendar
system is Gregorian.

## License

License: Creative Commons Attribution 4.0 International License
