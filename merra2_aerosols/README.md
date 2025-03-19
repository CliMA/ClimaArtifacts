# MERRA-2 Aerosol monthly mean data

This artifact converts [M2I3NVAER](https://disc.gsfc.nasa.gov/datasets/M2I3NVAER_5.12.4/summary) data to monthly means and converts the vertical dimension to altitude.

The `create_artifacts.jl` script creates two artifact, one on the MERRA 1.25 grid, and one
with a lowered horizontal and vertical resolution.

## Usage

1. Generate the three prerequisite files (.netrc, .urs_cookies, .dodsrc) for downloading
from Earthdata. See instructions [here](https://disc.gsfc.nasa.gov/information/howto?title=How%20to%20Generate%20Earthdata%20Prerequisite%20Files)

2. Run `julia --project create_artifact.jl`. This downloads a large amount of data, so you may
want to change `DATADIR` in `create_artifact.jl` to a different path.

## Requirements

- 2.4 TB of free disk space

## Downloaded data

The M2I3NVAER dataset is a collection of instantaneous, 3-dimensional data. There is data
for every three hours, at a 0.5° x 0.625° horizontal resolution and 72 model level vertical
resolution. The data spans from 1980-01-01 to present, and the data for each day is in a
seperate 3.9 GB file.

To reduce the required disk space, `create_artifacts.jl` downloads regridded and daily averaged
data using the [GES DISC Subsetter](https://disc.gsfc.nasa.gov/information/howto?title=How%20to%20use%20the%20Level%203%20and%204%20Subsetter%20and%20Regridder). `download_urls.txt`
contains the urls for each days data, with the data being averaged for the whole day, regridded
to the MERRA 1.25 grid using bilinear interpolation, and only containing selected variables.
The resulting data for each day is approximately 140 MB.

## Processing

The downloaded data's vertical coordinates are in model levels, which each have an associated pressure
thickness. There are 72 levels, with level 1 being the furthest from the surface and level 72 the
closest to the surface. During processing, the levels are converted to altitude over mean-sea level.

For each daily average dataset, the pressure thickness for each vertical level at each horizontal coordinate
is in the `DELP` variable, and the air density of each loevel is in the
`AIRDENS` variable. The surface elevation at each horizontal is obtained from
[M2C0NXASM](https://disc.gsfc.nasa.gov/datasets/M2C0NXASM_5.12.4/summary),
and is constant across time.

The model level dimesnion is converted to elevation of the center of the level using the hydrostatic equation

$\partial z = \frac{\partial p}{-g \rho}$

The center of the lowest level is calculated as the surface elevation plus half the
thickness of the level, which is computed by dividing `DELP` by `-g * AIRDENS`.
The center of the any non-bottom level is calculated as the center of the previous level,
plus half the thickness of the previous level, plus half the thickness of the current level. This is equivalent to calculating the center of any level as
the sum of the top of the previous level and half the thickness of the current level.

This continues for all levels, resulting in z coordinates for each horizontal point, time, and model level:


Next, a target z is created, with values from 10m to 80km. The data, which now has a calculated
altitude for each level, is interpolated to the target z using gridded linear interpolation.
If a z point is greater than the range of definition, the closest in-bounds point is used.

During this process the names of the variables are modified to follow those in the
aerosol_concentrations artifact. The conversions are below:

- SO4: SO4
- BCPHOBIC: CB1
- BCPHILIC: CB2
- OCPHOBIC: OC1
- OCPHILIC: OC2
- DU001 - DU005: DST01 - DST05
- SS001 - SS005: SSLT01 - SSLT05

After each daily data file is processed, they are averaged by month, with each
month's average placed on the 15th of that month.

## Output Files

### File Sizes

The full resolution output file is 53GB. The low resolution output file contains approximately
1/216th the data points, and is 285MB.

### Temporal Coverage

Both the full and low resolution output files contain monthly averages from 1980/01 to 2024/11.
The averages are placed on the 15th of each month.

### Spatial Coverage

#### Full resolution

- 1.25° latitude x 1.25° longititude horizontal grid
- -89.375N to 89.375N and -179.375E to 179.375E
- 42 vertical points from 10m to 80km


#### Low resolution

- 7.5° latitude x 7.5° longititude horizontal grid
- -89.375N to 83.125N and -179.375E to 173.125E
- 8 vertical points from 10m to 80km

### Variables

There are 15 data variables, all in units of kg/kg:

- CB1: Hydrophobic Black Carbon
- CB2: Hydrophilic Black Carbon
- OC1: Hydrophobic Organic Carbon (Particulate Matter)
- OC2: Hydrophilic Organic Carbon (Particulate Matter)
- SO4: Sulphate aerosol
- DST01, DST02, DST03, DST04, DST05: Dust Mixing Ratio (bin 1, bin 2, bin 3, bin 4, bin 5)
- SS001, SS002, SS003, SS004, SS005: Sea Salt Mixing Ratio (bin 1, bin 2, bin 3, bin 4, bin 5)

### Additional Variable

One additional variable, `z_sfc` is included. It is defined on the latitude
and longitude dimensions, and contains the surface elevation for that location.

## Citation

Global Modeling and Assimilation Office (GMAO) (2015), MERRA-2 inst3_3d_aer_Nv: 3d,3-Hourly,Instantaneous,Model-Level,Assimilation,Aerosol Mixing Ratio V5.12.4, Greenbelt, MD, USA, Goddard Earth Sciences Data and Information Services Center (GES DISC), Accessed:\[2025-01-23\], [10.5067/LTVB4GPCOTK2](https://doi.org/10.5067/LTVB4GPCOTK2)

## License

No license is specified for the downloaded data.
