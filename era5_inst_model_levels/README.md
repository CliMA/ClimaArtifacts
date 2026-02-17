# ERA5 Instantaneous Model Levels Initial Conditions

This artifact contains processed ERA5 reanalysis data from model levels for initializing atmospheric simulations. Model levels contain far more vertical points and extend higher than pressure levels, preventing initialization biases.

## File Summary

| File | Description |
|------|-------------|
| `era5_init_processed_internal_20100101_0000.nc` | Processed initial conditions file containing atmospheric variables interpolated to 32 h_elem horizontal grid (temperature, winds, humidity, surface geopotential, and others). Extends up to 70 km; dz = 150m |

**Dimensions:** `lon = 384`, `lat = 192`, `z = 467`

## Data Generation

The source code for generating this data is located in the CliMA [WeatherQuest](https://github.com/CliMA/WeatherQuest) repository, where additional documentation and use cases can be found.

To regenerate the data, go into `processing` and run:

### Step 1: Download ERA5 data

```bash
python get_initial_conditions.py \
    --output-dir /path/to/output/initial_conditions_amip \
    --date 2010-01-01 \
    --time 00:00 \
    --atmos-levels model
```

### Step 2: Process the data

```bash
julia --project preprocessing.jl \
    --start-datetime 20100101_0000 \
    --end-datetime 20100101_0000 \
    --data-dir /path/to/output/initial_conditions_amip
```
