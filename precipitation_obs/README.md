# Precipitation data from GPCP

This artifact contains monthly mean precipitation from the Global Precipitation Climatology Project (GPCP)
from January 1979 to September 2024. A current version of data, with data from January 1979 to the present
can be downloaded from the
NOAA: [GPCP Monthly Analysis Product](https://psl.noaa.gov/data/gridded/data.gpcp.html).

## Usage

To recreate the artifact:

Run `julia --project create_artifact.jl`

## Data Specifications

### Temporal Coverage

- Monthly values 1979/01 through 2024/09

### Spatial Coverage

- 88.75N - 88.75S, 1.25E - 358.75E,
- 2.5 degree latitude x 2.5 degree longitude global grid (144x72)

### Caveats

- The last 2 months are interim data. Interim data covers 2024/08 through latest

### Files

- This artifact contains one file, `precip.mon.mean.nc`, which is 20MB and contains the `precip` variable

### Description

The following description is taken directly from the [NOAA](https://psl.noaa.gov/data/gridded/data.gpcp.html):

The GPCP Monthly product provides a consistent analysis of global precipitation from an
integration of various satellite data sets over land and ocean and a gauge analysis over land.
Data from rain gauge stations, satellites, and sounding observations have been merged to estimate
monthly rainfall on a 2.5-degree global grid from 1979 to the present. The careful combination
of satellite-based rainfall estimates provides the most complete analysis of rainfall available
to date over the global oceans, and adds necessary spatial detail to the rainfall analyses over land.

### Variables

#### precip

- **long_name**: Average Monthly Rate of Precipitation
- **Dimensions**: lon × lat × time
- **Datatype**: Union{Missing, Float32}
- **units**: mm/day

## Citations and Usage Restrictions

This data is in the public domain and may be used freely, as long as you do not claim it as
your own, use in it a manner that implies affiliation with NOAA, or modify it and present it
as official government data. The NOAA also requests that they be acknowledged when the data
is used in documents or publications using this data.

### Citation

Adler, R.F., G.J. Huffman, A. Chang, R. Ferraro, P. Xie, J. Janowiak, B. Rudolf, U. Schneider,
S. Curtis, D. Bolvin, A. Gruber, J. Susskind, and P. Arkin,
2003: The Version 2 Global Precipitation Climatology Project (GPCP) Monthly Precipitation Analysis (1979-Present). J. Hydrometeor., 4,1147-1167.
