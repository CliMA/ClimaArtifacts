# EN4 Temperature and Salinity (January 2010)
This artifact contains EN4.2.2 data (with .g10 bias corrections) for observed subsurface ocean temperature and salinity profiles for the month of January 2010.
The data is interpolated onto a regular lat-lon grid with 1° resolution in the horizontal and 42 vertical levels.

Navigate to this directory `cd /path/to/en4_temperature_salinity_2010_01` and run `julia --project=. create_artifacts.jl`. This should generate a subfolder `en4_temperature_salinity_2010_01` containing the following file:
- `EN.4.2.2.f.analysis.g10.201001.nc` (26 MB)

## Citation

Good, S. A., M. J. Martin and N. A. Rayner, 2013. EN4: quality controlled ocean temperature and salinity profiles and monthly objective analyses with uncertainty estimates, *Journal of Geophysical Research: Oceans*, doi:10.1002/2013JC009067.

EN.4.2.2 data were obtained from https://www.metoffice.gov.uk/hadobs/en4/ and are © British Crown Copyright, Met Office, 2026, provided under a Non-Commercial Government Licence http://www.nationalarchives.gov.uk/doc/non-commercial-government-licence/version/2/