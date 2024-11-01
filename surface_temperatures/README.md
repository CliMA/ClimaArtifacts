# Surface Temperatures from BEST

This artifact contains high resolution monthly averages land and ocean surface temperatures from the Berkeley Earth Surface Temperature Project. The data ranges from 1850 to recent, and a current version of the data can be found [here](https://berkeleyearth.org/data/). All of the data is contained in one file, `Land_and_Ocean_LatLong1.nc`. After the file is downloaded, preprocessing is performed, and the preprocessed data is saved into the same file, with some unnecessary variables removed.

## Usage

To recreate the artifact:

Run `julia --project create_artifact.jl`

## Data Specifications

The following describes the `Land_and_Ocean_LatLong1.nc` file after pre-processing, which is around 420 MB at the time of the original creation of this artifact.

### Temporal Coverage

There are 2095 points in the time dimension, and the values are held in the `time` variable. In the original downloaded dataset, each time point is a decimal, where the integer part of the decimal refers the year, and the decimal refers to the center of the month the data point corresponds to. During pre-processing, these are converted to `DateTime` objects, where each monthly
average is centered on the 15th of the month. For example, the 2000th index of `time` is `2016-08-15T00:00:00`, and data at this point is the average for August of 2016.

### Spatial Coverage

The spatial variables are defined on a 1 degree latitude by 1 degree longitude grid. The longitude is in degrees east and ranges from -179.5 to 179.5, and the latitude is in degrees north and ranges from -89.5 to 89.5. The values are held in the `latitude` and `longitude` variables.

#### `land_mask`

This variable is defined on (longitude × latitude), and its values range from 0.0 to 1.0. The value of each cell is the fraction of the cell that corresponds
to land (as opposed to large bodies of water.)

#### `absolute_temperature`

This variable is defined on (longitude × latitude × month_number), and it contains the monthly mean Absolute Air Surface Temperature from 1850 to present in degrees C. This variable is produced during pre-processing by combining the `climatology` and `temperature` variables from the downloaded dataset.

`climatology`, which is removed during preprocessing, contains the Air Surface Temperature Climatology for each month, averaged from Jan 1951 to Dec 1980. For example, the first month refers to the estimate average of surface temperature for all Januaries from 1951 to 1980, the second month refers to the mean of all Februaries, and so on.

`temperature`, which is removed during preprocessing, contains the monthly mean Air Surface Temperature Anomaly from 1850 to present. Each point measures the local temperature anomaly. Points are recorded as missing
if the coverage diagnostic indicates that the locally available data provides less than a 20% constraint on the anomaly.

`absolute_temperature` is produced by adding the the corresponding month's `climatology` to each `temperature` monthly mean. If a data point is recorded as missing
in `temperature`, then the data point in also recorded as missing in `absolute_temperature`.

## Data Usage and Citation

This data is licensed under [Creative Commons BY-NC 4.0 International](https://creativecommons.org/licenses/by-nc/4.0/) for non-commercial use only. Attribution under CC BY-NC terms should be given to Berkeley Earth, including reference to [www.berkeleyearth.org](www.berkeleyearth.org) when possible.

The Berkeley Earth Land/Ocean Temperature Record (December 17, 2020):
Rohde, R. A. and Hausfather, Z.: , Earth System Science Data, 2020.
