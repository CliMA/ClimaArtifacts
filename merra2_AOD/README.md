# MERRA-2 Aerosol Optical Depth data

This artifact downloads data from [M2TMNXAER](https://disc.gsfc.nasa.gov/datasets/M2TMNXAER_5.12.4/summary) and merges it into one file. No pre-processing is done to the
data, but the two units attribute for the two unitless variables is changes from `1` to an
empty string.

## Usage

1. Generate the three prerequisite files (.netrc, .urs_cookies, .dodsrc) for downloading
from Earthdata. See instructions [here](https://disc.gsfc.nasa.gov/information/howto?title=How%20to%20Generate%20Earthdata%20Prerequisite%20Files)

2. Run `julia --project create_artifact.jl`

This requires approximately 470 MB of free storage.

## Downloaded Data

The M2TMNXAER (also known as tavgM_2d_aer_Nx) is a collection of time averaged,
2- dimensional data. The collection contains monthly mean data of assimilated aerosol
diagnostics from 1980-01-01 to the present at a 0.5° x 0.625° horizontal resolution. Each
monthly mean is contained in a seperate file.

`create_artifacts.jl` downloads the data using the [GES DISC Subsetter](https://disc.gsfc.nasa.gov/information/howto?title=How%20to%20use%20the%20Level%203%20and%204%20Subsetter%20and%20Regridder).
This allows downloading cropped and regridded data, and selecting only specific variables.
`download_urls.txt` contains a url for each month from 1980-01 to 2024-12, which requests
regridding to the MERRA 1.25 grid using bilinear interpolation, and only the `TOTEXTTAU`
and `TOTSCATAU` variables.

This results in 12 * (2024 - 1980) = 540 data files, which total to 150 MB.

## Output File

### File Size

The uncompressed artifact is 171 MB and the compressed artifact is 147 MB

### Temporal Coverage

Monthly averages from 1980-01 to 2024-12. Each month's average is placed on the 15th.

### Spatial Coverage

- 1.25° latitude x 1.25° longititude horizontal grid
- -89.375N to 89.375N and -179.375E to 179.375E

### Data Variables

Both variables only contain positive values and contain no missing points, NaNs, or Infs.

#### `TOTEXTTAU`: Total Aerosol Extinction AOT [550 nm]

- mean value of 0.126
- maximal value of 10.210

#### `TOTSCATAU`: Total Aerosol Scattering AOT [550 nm]

- mean value of 0.121
- maximal value of 9.044

## Citation

Global Modeling and Assimilation Office (GMAO) (2015), MERRA-2 tavgM_2d_aer_Nx: 2d,Monthly mean,Time-averaged,Single-Level,Assimilation,Aerosol Diagnostics V5.12.4, Greenbelt, MD, USA, Goddard Earth Sciences Data and Information Services Center (GES DISC), Accessed:
\[2025-02-10], [10.5067/FH9A0MLJPC7N](https://doi.org/10.5067/FH9A0MLJPC7N)

## License

No license is specified for the downloaded data.
