# Initial conditions for the optimal LAI model

This artifact (`optimal_lai_inputs.nc`) includes the spatially varying
initial conditions needed by the optimal LAI model (Zhou et al., 2025)
in ClimaLand. The data is on a 1° × 1° (360 × 180) longitude–latitude grid.

## Variables

| Variable | Units | Description |
|---|---|---|
| `gsl` | days | Growing season length – hybrid approach: LAI-based for seasonal regions (CV > 0.15), temperature-based (days with T > 0 °C) for non-seasonal regions. Minimum 30 days. |
| `a0_annual` | mol CO₂ m⁻² yr⁻¹ | Annual potential GPP computed with fAPAR = 1. |
| `precip_annual` | mol H₂O m⁻² yr⁻¹ | Mean annual precipitation, converted from ERA5 kg m⁻² s⁻¹. |
| `vpd_gs` | Pa | Average vapor pressure deficit during growing season months. |
| `lai_init` | m² m⁻² | Initial LAI from MODIS satellite data (first timestep). |
| `f0` | dimensionless | Spatially varying fraction of precipitation for transpiration from Zhou et al. (2025), regridded from 0.5° to 1°. |

## How it is generated

We obtain this data by first running the ClimaLand model, forced by
ERA5 data from 2008, for two years continuously. The script to do this is:
`ClimaLand.jl/experiments/long_runs/snowy_land_pmodel.jl`. The monthly diagnostic
output from that run provides the input files listed below.

The generation script (`optimal_lai_inputs.jl`) reads six input files
from this directory:

- `lai_1M_average.nc` – monthly mean MODIS LAI
- `a0a_1M_average.nc` – monthly mean annual potential GPP (diagnostic `a0a`)
- `tair_1M_average.nc` – monthly mean air temperature
- `precip_1M_average.nc` – monthly mean precipitation rate (ERA5, kg m⁻² s⁻¹)
- `vpd_1M_average.nc` – monthly mean vapor pressure deficit
- `f0.nc` – spatially varying f₀ from Zhou et al. (2025) at 0.5° resolution

Create the artifact by running:

```
julia --project data_laiopt/optimal_lai_inputs.jl
```

## Reference

Zhou, S., et al. (2025). *Global Change Biology*
