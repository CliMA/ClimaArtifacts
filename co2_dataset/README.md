# Data from Mauna Loa CO2

## Overview

This folder contains a script that downloads Mauna Loa CO2 monthly mean
data from the Global Monitoring Laboratory and creates an artifact containing
the data.

## Usage

To recreate the artifact:

Run `julia --project create_artifact.jl`

## Data Files

### `co2_mm_mlo.txt`

This .txt file contains monthly mean CO2 data from Mauna Loa.
The file is updated each month with the latest data. The details of
the data sources can be found inside the file, along with details on missing
data handling. The file contains monthly average CO2 as ppm and de-seasonalized average
CO2 as ppm from March 1958 to the present. It can be downloaded, along with a .csv version, from the NOAA [here](https://gml.noaa.gov/ccgg/trends/data.html)

#### Monthly Data Columns in order

- Year
- Month
- Decimal Date
- Monthly Average CO2 (ppm)
- De-Seasonalized Monthly Average CO2 (ppm)
- Number of Days Measured
- Standard Deviation of Daily CO2 data
- Uncertainty of Monthly Mean

### `co2_daily_mlo.txt`

This .txt file contains daily mean CO2 data as ppm from Mauna Loa.
The file is updated each consistently with the latest data. The details of
the data sources can be found inside the file. The file contains daily average CO2  May 19 1974 to the present. It can be downloaded, along with a .csv version, from the NOAA [here](https://gml.noaa.gov/ccgg/trends/data.html)

#### Daily Data Columns in order

- Year
- Month
- Day
- Decimal Date
- CO2 molfrac (ppm)

## References

Dr. Xin Lan, NOAA/GML (gml.noaa.gov/ccgg/trends/) and Dr. Ralph Keeling, Scripps Institution of Oceanography (scrippsco2.ucsd.edu/).

## License

This data is in the public domain and may be used freely by the public so long as you do not:

1. claim it is your own (e.g. by claiming copyright for NOAA information – see next paragraph)
2. use it in a manner that implies an endorsement or affiliation with NOAA
3. modify it in content and then present it as official government material. You also cannot present information of your own in a way that makes it appear to be official government information.

To ensure that GML receives fair credit for their work please include relevant citation text in publications. We encourage users to contact the data providers,
who can provide detailed information about the measurements and
scientific insight. In cases where the data are central to a
publication, coauthorship for data providers may be appropriate.
