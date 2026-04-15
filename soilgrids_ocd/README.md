# Soil Organic Carbon Density (OCD) from SoilGrids

This artifact provides soil organic carbon density (OCD) from SoilGrids 2.0 at 6 standard depth
layers and ~5 km ans 1x1 degree resolution, matching the grid of the existing `soilgrids` artifact.

## Variable

| Variable | Description | Output units |
|----------|-------------|--------------|
| `ocd`    | Soil organic carbon density | kg/m³ |

## Depth layers

Data is provided at the 6 SoilGrids standard depth layers:
`0-5 cm`, `5-15 cm`, `15-30 cm`, `30-60 cm`, `60-100 cm`, `100-200 cm`

The depth coordinate `z` stores the midpoint of each layer in metres:
`[-0.025, -0.1, -0.225, -0.45, -0.8, -1.5]`

## Processing steps

1. **Download**: Run `download_soilgrids_ocd.sh` to retrieve OCD GeoTIFF files from SoilGrids
   (requires `gdal_translate` and `gdalwarp`).
2. **Convert to NetCDF**: Run `transform_geotiff_to_netcdf.sh` to convert each `.tif` to `.nc`.
3. **Create artifact**: Run `julia --project create_artifacts.jl <path/to/soilgridsOCD_nc>`.
   This converts raw integer values (hg/m³) to SI units (kg/m³) and writes two NetCDF files:
   - `soilgridsOCS/soil_ocd_soilgrids.nc` — full resolution (~5 km)
   - `soilgridsOCS_lowres/soil_ocd_soilgrids_lowres.nc` — downsampled by area weighted averaging (~1 degree)

## Unit conversion

SoilGrids stores OCD as integers in units of hg/m³ (hectograms per cubic metre).
Conversion: `ocd_kg_m3 = raw_integer * 0.1`.
see https://www.isric.org/explore/soilgrids/faq-soilgrids if needed.

## License

The raw data is provided by SoilGrids under a Creative Commons BY 4.0 License.
See https://soilgrids.org for details.

## References

Poggio, L., de Sousa, L. M., Batjes, N. H., Heuvelink, G. B. M., Kempen, B., Ribeiro, E., and
Rossiter, D.: SoilGrids 2.0: producing soil information for the globe with quantified spatial
uncertainty, SOIL, 7, 217–240, 2021. DOI: https://doi.org/10.5194/soil-7-217-2021
