# Spun-up initial conditions for a deeper water table

## Overview

Initial conditions for the global ClimaLand land model (soil, snow, canopy) after a
140-year spin-up, the last 40 years with a deeper water table: the TOPMODEL parameter
`f_over` is 0.7 m⁻¹ instead of the default 3.28 m⁻¹, and the code has frozen-ground
changes that are not on ClimaLand main (see How it was made).

The file has the same variables, grid and format as
[`rosetta_spunup_ic`](https://github.com/CliMA/ClimaArtifacts/tree/main/rosetta_spunup_ic),
so it can replace it as the initial condition of a run.

> [!IMPORTANT]
> This state belongs to `f_over` = 0.7. With the default 3.28, the water table rises back
> toward the shallow equilibrium of main. The frozen-ground changes come from the closed
> CliMA/ClimaLand.jl#1958 and will not be merged (CliMA/ClimaLand.jl#1963). This state has
> not been tested with main's code and `f_over` = 0.7 alone.

## Contents

`deep_water_table_spunup_ic.nc` (12.2 MB, sha256
`c809edd8b7e75043d3374d72bf82d8902e530fc223997cef31d74aa93821ede5`), in Float32:

| Variable | Dimensions | Units | Content | Range |
|---|---|---|---|---|
| `swc` | (lon, lat, z) | m³/m³ | volumetric fraction of liquid water, `soil.ϑ_l` | 0.048 to 0.729 |
| `si` | (lon, lat, z) | m³/m³ | volumetric fraction of ice, `soil.θ_i` | 0 to 0.521 |
| `sie` | (lon, lat, z) | J/m³ | volumetric internal energy of the soil, `soil.ρe_int` | -1.93e8 to 1.03e8 |
| `swe` | (lon, lat) | m | snow water equivalent | 0 to 660 |
| `lwp` | (lon, lat) | m | leaf water potential | -153 to 347 |

- `lon` (-180, ..., 179) and `lat` (-90, ..., 89) are in degrees, 1° apart.
- `z` holds the centers of the 15 soil layers of the 15 m column, in m, negative below the
  surface, from -13.5 to -0.025.
- Each value is the mean over February 2140 of the spin-up, a monthly diagnostic. Start
  runs from it on March 1, as the ClimaLand long runs do.
- The 42,380 cells outside the model's land points hold the mean of the land values, as in
  `rosetta_spunup_ic` (e.g., 10.7 m of `swe`, from the ice sheets). The 22,420 land points
  hold the model state.
- The global attribute `source` gives the month and the output directory of the spin-up.

## How it was made

1. **Start:** the `rosetta_spunup_ic` artifact (git-tree-sha1 `2ac7808d…`).
2. **100 years with main's defaults.**
   - Code: ClimaLand main at `ba89f1f8e`, with the spin-up script
     `experiments/long_runs/spinup_model.jl` (a version of it is in the closed
     CliMA/ClimaLand.jl#1957).
   - Forcing: ERA5 1979–1998, repeated; MODIS LAI climatology.
   - Model: canopy, lake, snow and soil on the 1° grid, 15 m soil column with no flux at
     the bottom; Δt 900 s; GPU.
   - Five 20-year cycles, from 2000-03 to 2100-03.
3. **40 more years with the deeper water table,** from the end of step 2 (2100-03 to
   2140-03).
   - Code: branch `ar/hydrology_spinup_A` at `18124131`, not yet on GitHub. It has the physics of
     CliMA/ClimaLand.jl#1958 except its change to the saturated area:
     - drainage of water perched on the frost table;
     - infiltration into frozen soil over its permeable fraction;
     - TOPMODEL land points with f_max = 0 get the mean f_max of the other points
       (CliMA/ClimaLand.jl#1961 uses the constant 0.39 instead);
     - the `wtd`, `sr`, `ssr` and `et` diagnostics.
   - Parameters: main's defaults, except `f_over` = 0.7 m⁻¹ (3.28 on main).
   - Same forcing and grid as step 2.
4. **This file:** the February 2140 monthly means of `swc`, `si` and `sie` (on lon, lat,
   z) and of `swe` and `lwp` (on lon, lat), written in the format of
   `rosetta_spunup_ic/create_artifacts.jl`: Float32, the same names and attributes, and
   NaN replaced by the mean of the other values. That script takes the last month of the
   output instead of a given one.

## State at the end of the spin-up

From the 40 years of step 3:

- **Water storage:** -115 mm over the first 5 years, -50 mm more by year 13, then flat.
  Between the two 20-year cycles, for the same forcing year, the change is -0.8 mm/yr at
  the end, and shrinking.
- **Drift over the last 10 years of the two cycles** (95th percentile over the land):
  terrestrial water storage 8.4 mm/yr, latent heat flux 0.58 W m⁻², temperature
  0.004 K/yr. The 100 years of step 2 ended at 8.3, 0.81 and 0.003. The residual drift is
  deep drainage in the arid belt at 10–30°N, and perennial snow that keeps growing. `swe`
  reaches 660 m on the Antarctic Peninsula.
- **Water table against Fan et al. (2017)** (`fan2017_water_table_depth_1degree`), from
  the model's `wtd` diagnostic over the last year: RMSE 5.02 m, bias -0.84 m. North of
  50°N it is still too deep (8.8 m against 5.5 m).

CliMA/ClimaLand.jl#1963 compares this configuration with main: the water table, the
carbon fluxes and ET against MODIS improve, but the tropics dry out and the latent heat
flux falls by about 2 W m⁻² against ERA5.

## Usage

Set `f_over` with a parameter TOML:

```toml
["f_over"]
value = 0.7
type = "float"
```

and pass the file to the simulation:

```julia
using ClimaUtilities.ClimaArtifacts
ic_path = joinpath(
    @clima_artifact("deep_water_table_spunup_ic", context),
    "deep_water_table_spunup_ic.nc",
)
simulation = LandSimulation(
    t0, tf, Δt, model;
    set_ic! = ClimaLand.Simulations.make_set_initial_state_from_file(ic_path, model),
)
```

## Recreating the artifact

`create_artifacts.jl` packages the file written in step 4. It checks the sha256 above,
the variables and the grid, copies the file, and starts the guided upload:

```
julia --project -e 'using Pkg; Pkg.instantiate()'
julia --project create_artifacts.jl /path/to/hydro_A_2140-02_ic.nc
```

## References

Fan Y, Miguez-Macho G, Jobbágy EG, Jackson RB, Otero-Casal C (2017) Hydrologic regulation of
plant rooting depth. Proc Natl Acad Sci USA 114(40):10572–10577.
https://doi.org/10.1073/pnas.1712381114
