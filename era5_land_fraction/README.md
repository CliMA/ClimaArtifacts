# ERA5 Land Fraction

## Overview

This artifact provides a preprocessed land fraction field derived from the ERA5 reanalysis
land-sea mask (lsm) variable at 0.1° resolution.

- `era5_land_fraction/era5_land_fraction.nc` (0.1° resolution, compressed)

## Data Description

The land fraction field represents the fraction of each grid cell that is land (as opposed
to ocean or inland water). Values range from 0 (pure ocean) to 1 (pure land), with
intermediate values representing coastal or partially-land grid cells.

### Variable Information

| Variable | Dimensions | Units | Description |
|----------|------------|-------|-------------|
| `lsm`    | (lon, lat) | 1     | Land fraction (0 = ocean, 1 = land) |
| `lon`    | (lon,)     | degrees_east | Longitude |
| `lat`    | (lat,)     | degrees_north | Latitude (ascending order) |

## Preprocessing

The raw ERA5 land-sea mask file is preprocessed to:
1. Remove the singleton time dimension (ERA5 lsm is static but stored with a time coordinate)
2. Ensure latitude is in ascending order (-90° to 90°) for compatibility with interpolation
3. Handle any fill/missing values by replacing with NaN
4. Output a clean 2D NetCDF file in CF-1.6 convention

## Usage

This artifact can be used with `SpaceVaryingInput` in ClimaCoupler/ClimaUtilities:

```julia
using ClimaUtilities.ClimaArtifacts: @clima_artifact
using ClimaUtilities.SpaceVaryingInputs: SpaceVaryingInput

# comms_ctx: ClimaComms context fof artifact downloads
# boundary_space: ClimaCore 2D horizontal space (e.g., a SpectralElementSpace2D)

land_fraction_data = joinpath(
    @clima_artifact("era5_land_fraction", comms_ctx),
    "era5_land_fraction.nc",
)
land_fraction = SpaceVaryingInput(land_fraction_data, "lsm", boundary_space)
```

## Comparison with ETOPO-based Land-Sea Mask

The era5 land fraction artifact is a continuous dataset containing land fractions [0.0 - 1.0], used by ECMWF.
The era5 land fraction considers both oceans and inland lakes.
The existing ETOPO-based artifacts provide binary (0/1) land-sea masks at three resolutions:
- `landsea_mask_30arcseconds` (30 arc-second, ~1 km)
- `landsea_mask_60arcseconds` (60 arc-second, ~2 km)
- `landsea_mask_1deg` (1 degree, ~111 km)

Key differences:
- **Values**: ERA5 is fractional [0, 1]; ETOPO is binary (0/1)
- **Source**: ERA5 uses IFS land surface scheme (coastal areas, lakes, and ice sheets); ETOPO uses topography
- **Resolution**: ERA5 at 0.1° (~11 km); ETOPO at 30", 60", or 1°

Choose the appropriate mask based on your application:
- Use `landsea_mask_*` for binary land/ocean distinction based on topography
- Use `era5_land_fraction` for fractional land coverage consistent with ERA5 forcing data

## Source

ECMWF ERA5 Reanalysis
- Variable: Land-sea mask (lsm)
- Available from: [Copernicus Climate Data Store](https://cds.climate.copernicus.eu/)
- Documentation: [ERA5 documentation](https://confluence.ecmwf.int/display/CKB/ERA5)

## References

Hersbach, H., Bell, B., Berrisford, P., et al. (2020). The ERA5 global reanalysis.
Quarterly Journal of the Royal Meteorological Society, 146(730), 1999-2049.
https://doi.org/10.1002/qj.3803
