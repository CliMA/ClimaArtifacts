# Live woody carbon of Xu et al. (2021)

This artifact holds `xusaatchi_woody_carbon_1deg.nc`, the 2000-2019 mean carbon of the
live woody vegetation, above and below ground, of Xu et al. (2021), on a 1° × 1° grid
(360 × 180, longitudes in [-180, 180), latitudes ascending):

| Variable | Units | Description |
|---|---|---|
| `woody_carbon` | kg C m⁻² | Carbon in live woody vegetation, NaN over ocean |

ClimaLand compares it with the live carbon of its prognostic carbon pools in the
vegetation leaderboard.

## Usage

To recreate the artifact:
1. Navigate to this directory in the terminal.
1. Run `julia --project create_artifact.jl`

The script downloads `XuSaatchi.nc` from ILAMB (the annual maps at 0.5°, in Mg C ha⁻¹),
checks its SHA256, averages the 20 years, converts to kg C m⁻², and averages the 0.5°
cells into 1° blocks, which are land where at least half of their cells are.

## Source

[https://www.ilamb.org/ILAMB-Data/DATA/biomass/XuSaatchi2021/XuSaatchi.nc](https://www.ilamb.org/ILAMB-Data/DATA/biomass/XuSaatchi2021/XuSaatchi.nc),
coarsened by ILAMB from the 0.1° maps of the dataset
([https://doi.org/10.5281/zenodo.4161694](https://doi.org/10.5281/zenodo.4161694)).

## References

Xu, L., Saatchi, S. S., Yang, Y., Yu, Y., Pongratz, J., Bloom, A. A., Bowman, K., Worden,
J., Liu, J., Yin, Y., Domke, G., McRoberts, R. E., Woodall, C., Nabuurs, G.-J.,
de-Miguel, S., Keller, M., Harris, N., Maxwell, S., and Schimel, D. (2021). Changes in
global terrestrial live biomass over the 21st century. Science Advances, 7(27),
eabe9829. https://doi.org/10.1126/sciadv.abe9829

## License

Creative Commons Attribution 4.0 International (CC BY 4.0), the license of the dataset.
