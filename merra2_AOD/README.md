# MERRA-2 Aerosol Optical Depth data

`create_artifact.jl` downloads data from [M2TMNXAER](https://disc.gsfc.nasa.gov/datasets/M2TMNXAER_5.12.4/summary) and merges it into one file. No pre-processing is done to the
data, but the units attribute for unitless variables are changed from `1` to an empty string, and the monthly means are shifted from the 1st to the 15th.
The script then creates a thinned dataset from the merged full resolution data.

The resulting artifacts are named `merra2_AOD.nc` and `merra2_AOD_lowres.nc`.

## Usage

1. Generate the three prerequisite files (.netrc, .urs_cookies, .dodsrc) for downloading
from Earthdata. See instructions [here](https://disc.gsfc.nasa.gov/information/howto?title=How%20to%20Generate%20Earthdata%20Prerequisite%20Files)

2. Run `julia --project create_artifact.jl`

This requires approximately 3 GB of free storage.

## Downloaded Data

The M2TMNXAER (also known as tavgM_2d_aer_Nx) is a collection of time averaged,
2- dimensional data. The collection contains monthly mean data of assimilated aerosol
diagnostics from 1980-01-01 to the present at a 0.5° x 0.625° horizontal resolution. Each
monthly mean is contained in a seperate file.

`create_artifacts.jl` downloads the data using the [GES DISC Subsetter](https://disc.gsfc.nasa.gov/information/howto?title=How%20to%20use%20the%20Level%203%20and%204%20Subsetter%20and%20Regridder).
This allows downloading cropped and regridded data, and selecting only specific variables.
`download_urls.txt` contains a url for each month from 1980-01 to 2024-12, which requests the column mass density, extinction AOT [550 nm], and Scattering AOT [550 nm] for black carbon, dust, organic carbon, sea salt,
and SO4, along with total aerosol extinction AOT [550 nm] and Scattering AOT [550 nm]. The urls also request
regridding to the MERRA 1.25 grid using bilinear interpolation.

This results in 12 * (2024 - 1980) = 540 data files.

## Output Files

### File Size

The full resolution artifact is 1.4 GB.
The uncompressed low resolution artifact is 162 MB, and the compressed low resolution artifact
is 143 MB.

### Temporal Coverage

Monthly averages from 1980-01 to 2024-12. Each month's average is placed on the 15th.

### Spatial Coverage

#### Full Resolution

- 1.25° latitude x 1.25° longititude horizontal grid
- -89.375N to 89.375N and -179.375E to 179.375E

#### Low Resolution

- 3.75° latitude x 3.75° longititude horizontal grid
- -89.375N to 86.875N and -179.375E to 176.875E

### Data Variables

All variables only contain positive values and contain no missing points, NaNs, or Infs.

- `BCCMASS` : Black Carbon Column Mass Density (kg/m^2)
- `BCEXTTAU`: Black Carbon Extinction AOT [550 nm]
- `BCSCATAU` : Black Carbon Scattering AOT [550 nm]

- `DUCMASS` : Dust Column Mass Density (kg/m^2)
- `DUEXTTAU`: Dust Extinction AOT [550 nm]
- `DUSCATAU` : Dust Scattering AOT [550 nm]

- `OCCMASS` : Organic Carbon Column Mass Density \_\_ENSEMBLE\_\_  (kg/m^2)
- `OCEXTTAU`: Organic Carbon Extinction AOT \_\_ENSEMBLE\_\_  [550 nm]
- `OCSCATAU` : Organic Carbon Scattering AOT \_\_ENSEMBLE\_\_ [550 nm]

- `SSCMASS` : Sea Salt Column Mass Density (kg/m^2)
- `SSEXTTAU`: Sea Salt Extinction AOT [550 nm]
- `SSSCATAU` : Sea Salt Scattering AOT [550 nm]

- `SO4CMASS` : SO4 Column Mass Density \_\_ENSEMBLE\_\_  (kg/m^2)
- `SUEXTTAU`: SO4 Extinction AOT \_\_ENSEMBLE\_\_  [550 nm]
- `SUSCATAU` : SO4 Scattering AOT \_\_ENSEMBLE\_\_  [550 nm]

- `TOTEXTTAU`: Total Aerosol Extinction AOT [550 nm]
- `TOTSCATAU`: Total Aerosol Scattering AOT [550 nm]

Note that "SUSCATAU" is greater than "SUEXTTAU" at some points during 2021-07

## Citation

Global Modeling and Assimilation Office (GMAO) (2015), MERRA-2 tavgM_2d_aer_Nx: 2d,Monthly mean,Time-averaged,Single-Level,Assimilation,Aerosol Diagnostics V5.12.4, Greenbelt, MD, USA, Goddard Earth Sciences Data and Information Services Center (GES DISC), Accessed:
\[2025-02-10], [10.5067/FH9A0MLJPC7N](https://doi.org/10.5067/FH9A0MLJPC7N)

## License

No license is specified for the downloaded data.
