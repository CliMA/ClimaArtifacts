"""
Compute initial conditions for the optimal LAI model.

This script generates spatially varying initial conditions:
- GSL: Growing season length (days) - longest continuous above-0°C period, following Zhou et al. (2025)
- A0_annual: Annual potential GPP (mol CO₂ m⁻² yr⁻¹) from P-model simulation
- precip_annual: Mean annual precipitation (mol H₂O m⁻² yr⁻¹)
- vpd_gs: Average VPD during growing season (Pa)
- lai_init: Initial LAI from MODIS (m² m⁻²) - first timestep of satellite data
- f0: Spatially varying fraction of precipitation for transpiration (dimensionless) from Zhou et al.

GSL follows Zhou et al. (2025): the longest continuous above-0°C period (longer than 5 days).
With monthly data, this is the longest continuous run of months with mean T > 0°C.
Minimum GSL = 30 days for numerical stability in ice-covered regions.

The f₀×P/A₀ water limitation term in LAI_max follows Zhou et al. (2025, Eq. 11).

Output: NetCDF file with all initial condition variables on (lon, lat) grid.
"""

using NCDatasets
using Statistics
using ClimaArtifactsHelper

# Configuration
LAI_FILE = joinpath(@__DIR__, "lai_1M_average.nc")
A0_FILE = joinpath(@__DIR__, "a0a_1M_average.nc")
TAIR_FILE = joinpath(@__DIR__, "tair_1M_average.nc")
PRECIP_FILE = joinpath(@__DIR__, "precip_1M_average.nc")  # units: kg m⁻² s⁻¹
VPD_FILE = joinpath(@__DIR__, "vpd_1M_average.nc")
F0_FILE = joinpath(@__DIR__, "f0.nc")  # Zhou et al. spatially varying f0
OUTPUT_DIR = joinpath(@__DIR__, "optimal_lai_inputs_artifact")
mkpath(OUTPUT_DIR)
OUTPUT_FILE = joinpath(OUTPUT_DIR, "optimal_lai_inputs.nc")

# GSL parameters (Zhou et al. 2025)
FREEZING_TEMP = 273.15  # K (0°C) - threshold for growing season
MIN_GSL = 30.0  # Minimum GSL in days (for numerical stability in ice-covered regions)

"""
    mean_annual_cycle(ts::Vector{T}) -> Vector{T}

Compute the mean annual cycle (12 monthly values) from a time series
that must contain complete years (length ≥ 12 and a multiple of 12).
Averages across all years present.
"""
function mean_annual_cycle(ts::Vector{T}) where {T}
    n = length(ts)
    @assert n >= 12 && mod(n, 12) == 0 "Time series length must be ≥ 12 and a multiple of 12, got $n"
    nyears = n ÷ 12
    monthly = reshape(ts, 12, nyears)
    return vec(mean(monthly, dims = 2))
end

function compute_gsl_from_temperature(tair_timeseries::Vector{T}) where {T}
    """
    Compute GSL from monthly temperature following Zhou et al. (2025):
    GSL = length of the longest continuous above-0°C period longer than 5 days.

    With monthly data, we find the longest continuous run of months with
    mean T > 0°C (any single month ≈ 30 days already exceeds the 5-day
    threshold). Handles wrap-around for Southern Hemisphere summers.
    """
    # Handle NaN
    valid = .!isnan.(tair_timeseries)
    if !any(valid)
        return T(NaN)
    end

    tair_monthly = mean_annual_cycle(tair_timeseries)

    # Replace NaN with very cold temp (won't count as growing)
    tair_monthly = [isnan(x) ? T(200) : x for x in tair_monthly]

    above = [t > FREEZING_TEMP for t in tair_monthly]

    # Find longest continuous run of above-freezing months,
    # handling wrap-around by doubling the cycle
    above_doubled = vcat(above, above)
    max_run = 0
    current_run = 0
    for a in above_doubled
        if a
            current_run += 1
        else
            current_run = 0
        end
        max_run = max(max_run, current_run)
    end
    # Cap at 12 months (full year)
    max_run = min(max_run, 12)

    # Convert months to days
    gsl = max_run * T(365.25 / 12)

    return gsl
end


function compute_annual_precipitation(precip_timeseries::Vector{T}) where {T}
    """
    Compute mean annual precipitation from monthly precipitation rates.

    Args:
        precip_timeseries: Vector of monthly precipitation rates (kg m⁻² s⁻¹)

    Returns:
        precip_annual: Mean annual precipitation (mol H₂O m⁻² yr⁻¹), always positive

    Conversion:
        kg m⁻² s⁻¹ × (s yr⁻¹) → kg m⁻² yr⁻¹ (= mm yr⁻¹)
        1 mm = 1 kg m⁻² = 1000 g m⁻²; 1000 / 18.015 ≈ 55.51 mol H₂O m⁻²
    """
    # Handle NaN
    valid = .!isnan.(precip_timeseries)
    if !any(valid)
        return T(NaN)
    end

    precip_monthly = mean_annual_cycle(precip_timeseries)

    # Replace NaN with 0 for calculations and take absolute value
    precip_monthly = [isnan(x) ? T(0) : abs(x) for x in precip_monthly]

    seconds_per_month = T(365.25 * 24 * 3600 / 12)

    # Convert from kg m⁻² s⁻¹ to mol H₂O m⁻² yr⁻¹
    # 1 kg m⁻² = 1 mm = 1000 g m⁻²; Molar mass of water = 18.015 g/mol
    # So: 1 kg m⁻² = 1000 / 18.015 mol H₂O m⁻² ≈ 55.51 mol m⁻²
    MM_TO_MOL_H2O = T(1000.0 / 18.015)

    # Annual precipitation = sum of (monthly_rate × seconds_per_month) × conversion
    # kg m⁻² s⁻¹ × s → kg m⁻² (= mm) per month, sum over 12 months → mm yr⁻¹ → mol H₂O m⁻² yr⁻¹
    precip_annual_mm = sum(precip_monthly) * seconds_per_month
    precip_annual = precip_annual_mm * MM_TO_MOL_H2O

    return precip_annual
end

function get_growing_season_mask(tair_ts::Vector{T}) where {T}
    """
    Determine which months are in the growing season following Zhou et al. (2025):
    the longest continuous above-0°C period.

    Returns a 12-element boolean vector indicating growing season months.
    Handles wrap-around for Southern Hemisphere summers.
    """
    tair_monthly = mean_annual_cycle(tair_ts)

    # Replace NaN with very cold temp (won't count as growing)
    tair_monthly = [isnan(x) ? T(200) : x for x in tair_monthly]

    above = [t > FREEZING_TEMP for t in tair_monthly]

    # Find the longest continuous run of above-freezing months,
    # handling wrap-around by doubling the cycle
    above_doubled = vcat(above, above)
    best_run_len = 0
    best_run_end = 0
    current_run = 0
    for i in eachindex(above_doubled)
        if above_doubled[i]
            current_run += 1
        else
            current_run = 0
        end
        if current_run > best_run_len
            best_run_len = current_run
            best_run_end = i
        end
    end
    best_run_len = min(best_run_len, 12)

    # Build mask: mark the months belonging to the longest run
    mask = falses(12)
    for k in 0:(best_run_len - 1)
        mask[mod1(best_run_end - k, 12)] = true
    end

    return mask
end

function compute_vpd_growing_season(
    vpd_timeseries::Vector{T},
    tair_ts::Vector{T},
) where {T}
    """
    Compute average VPD during the growing season following Zhou et al. (2025).

    Growing season is the longest continuous above-0°C period.

    Args:
        vpd_timeseries: Vector of monthly VPD values (Pa)
        tair_ts: Vector of monthly temperature values (K)

    Returns:
        vpd_gs: Mean VPD during growing season (Pa)
    """
    # Handle NaN
    valid = .!isnan.(vpd_timeseries)
    if !any(valid)
        return T(NaN)
    end

    # Get mean annual cycle for VPD
    vpd_monthly = mean_annual_cycle(vpd_timeseries)

    # Get growing season mask
    gs_mask = get_growing_season_mask(tair_ts)

    # Replace NaN with 0 for calculations
    vpd_monthly = [isnan(x) ? T(0) : x for x in vpd_monthly]

    # Compute mean VPD during growing season
    gs_vpd = vpd_monthly[gs_mask]
    if isempty(gs_vpd)
        # No growing season months (very cold region), return annual mean
        return mean(vpd_monthly)
    end

    return mean(gs_vpd)
end

function load_and_regrid_f0(
    f0_file::String,
    target_lon::Vector,
    target_lat::Vector,
)
    """
    Load f0 from Zhou et al. NetCDF file and regrid to target grid.

    Regrids by averaging all source cells whose centers fall within each
    target cell's ±0.5° box. Works for any source resolution.

    Returns:
        f0_regridded: Matrix of f0 values on target grid (nlon × nlat)
    """
    ds = NCDataset(f0_file)
    f0_raw = ds["f0"][:, :, 1]
    f0_lon = ds["lon"][:]
    f0_lat = ds["lat"][:]
    close(ds)

    # Convert missing to NaN
    f0_data = Float64.(replace(f0_raw, missing => NaN))

    nlon_target = length(target_lon)
    nlat_target = length(target_lat)
    f0_regridded = fill(NaN, nlon_target, nlat_target)

    # Average source cells whose centers fall within each 1° target box
    for j in 1:nlat_target
        lat_lo = target_lat[j] - 0.5
        lat_hi = target_lat[j] + 0.5
        lat_mask = (f0_lat .>= lat_lo) .& (f0_lat .< lat_hi)

        for i in 1:nlon_target
            lon_lo = target_lon[i] - 0.5
            lon_hi = target_lon[i] + 0.5

            # Handle periodic longitude boundary
            if lon_hi > 180
                lon_mask = (f0_lon .>= lon_lo) .| (f0_lon .< lon_hi - 360)
            elseif lon_lo < -180
                lon_mask = (f0_lon .>= lon_lo + 360) .| (f0_lon .< lon_hi)
            else
                lon_mask = (f0_lon .>= lon_lo) .& (f0_lon .< lon_hi)
            end

            vals = f0_data[lon_mask, lat_mask]
            valid_vals = filter(!isnan, vec(vals))
            if !isempty(valid_vals)
                f0_regridded[i, j] = mean(valid_vals)
            end
        end
    end

    return f0_regridded
end

function main()
    println("Loading LAI data from: $LAI_FILE")
    ds_lai = NCDataset(LAI_FILE)
    lai = ds_lai["lai"][:, :, :]  # (time, lon, lat)
    lon = ds_lai["lon"][:]
    lat = ds_lai["lat"][:]
    close(ds_lai)

    println("Loading A0_annual data from: $A0_FILE")
    ds_a0 = NCDataset(A0_FILE)
    a0_annual = ds_a0["a0a"][:, :, :]  # (time, lon, lat)
    close(ds_a0)

    println("Loading temperature data from: $TAIR_FILE")
    ds_tair = NCDataset(TAIR_FILE)
    tair = ds_tair["tair"][:, :, :]  # (time, lon, lat)
    close(ds_tair)

    println("Loading precipitation data from: $PRECIP_FILE")
    ds_precip = NCDataset(PRECIP_FILE)
    precip = ds_precip["precip"][:, :, :]  # (time, lon, lat) in kg m⁻² s⁻¹
    close(ds_precip)

    println("Loading VPD data from: $VPD_FILE")
    ds_vpd = NCDataset(VPD_FILE)
    vpd = ds_vpd["vpd"][:, :, :]  # (time, lon, lat) in Pa
    close(ds_vpd)

    println("Loading and regridding f0 data from: $F0_FILE")
    f0 = load_and_regrid_f0(F0_FILE, lon, lat)
    println("f0 regridded to target grid")

    nlon, nlat = length(lon), length(lat)
    ntime = size(lai, 1)
    println("Grid size: $nlon x $nlat, $ntime time steps")

    # Extract initial LAI from first timestep of MODIS data
    lai_init = lai[1, :, :]  # First timestep
    println("Initial LAI (MODIS first timestep) extracted")

    # Allocate output arrays
    gsl = fill(NaN, nlon, nlat)
    a0_out = fill(NaN, nlon, nlat)
    precip_annual = fill(NaN, nlon, nlat)
    vpd_gs = fill(NaN, nlon, nlat)

    # Compute GSL, A0, precip_annual, and vpd_gs for each grid cell
    println("Computing GSL, A0_annual, precip_annual, and vpd_gs...")
    for i in 1:nlon
        for j in 1:nlat
            # Extract time series for this pixel
            lai_ts = Float64.(lai[:, i, j])
            a0_ts = Float64.(a0_annual[:, i, j])
            tair_ts = Float64.(tair[:, i, j])
            precip_ts = Float64.(precip[:, i, j])
            vpd_ts = Float64.(vpd[:, i, j])

            # Compute GSL following Zhou et al. (2025)
            gsl[i, j] = max(compute_gsl_from_temperature(tair_ts), MIN_GSL)

            # Use last time point for A0_annual (model spins up from uniform initial value)
            a0_last = a0_ts[end]
            if !isnan(a0_last)
                a0_out[i, j] = a0_last
            end

            # Compute mean annual precipitation
            precip_annual[i, j] = compute_annual_precipitation(precip_ts)

            # Compute average VPD during growing season
            vpd_gs[i, j] = compute_vpd_growing_season(vpd_ts, tair_ts)
        end
    end

    # Statistics
    valid_gsl = filter(!isnan, vec(gsl))
    valid_a0 = filter(!isnan, vec(a0_out))
    valid_precip = filter(!isnan, vec(precip_annual))
    valid_vpd = filter(!isnan, vec(vpd_gs))

    println("\nGSL statistics (Zhou et al. 2025: longest continuous above-0°C period):")
    println("  Valid points: $(length(valid_gsl))")
    println("  Range: $(minimum(valid_gsl)) - $(maximum(valid_gsl)) days")
    println("  Mean: $(round(mean(valid_gsl), digits=1)) days")

    # Check for zeros
    n_zeros = sum(valid_gsl .== 0)
    println("  Points with GSL=0: $n_zeros")

    println("\nA0_annual statistics:")
    println("  Valid points: $(length(valid_a0))")
    println(
        "  Range: $(round(minimum(valid_a0), digits=1)) - $(round(maximum(valid_a0), digits=1)) mol CO2 m^-2 yr^-1",
    )
    println("  Mean: $(round(mean(valid_a0), digits=1)) mol CO2 m^-2 yr^-1")

    println("\nPrecip_annual statistics:")
    println("  Valid points: $(length(valid_precip))")
    println(
        "  Range: $(round(minimum(valid_precip), digits=1)) - $(round(maximum(valid_precip), digits=1)) mol H2O m^-2 yr^-1",
    )
    println("  Mean: $(round(mean(valid_precip), digits=1)) mol H2O m^-2 yr^-1")
    println(
        "  (Equivalent to $(round(minimum(valid_precip) * 18.015 / 1000, digits=1)) - $(round(maximum(valid_precip) * 18.015 / 1000, digits=1)) mm yr^-1)",
    )

    println("\nVPD_gs (growing season) statistics:")
    println("  Valid points: $(length(valid_vpd))")
    println(
        "  Range: $(round(minimum(valid_vpd), digits=1)) - $(round(maximum(valid_vpd), digits=1)) Pa",
    )
    println("  Mean: $(round(mean(valid_vpd), digits=1)) Pa")

    valid_lai_init = filter(!isnan, vec(lai_init))
    println("\nLAI_init (MODIS first timestep) statistics:")
    println("  Valid points: $(length(valid_lai_init))")
    println(
        "  Range: $(round(minimum(valid_lai_init), digits=2)) - $(round(maximum(valid_lai_init), digits=2)) m² m⁻²",
    )
    println("  Mean: $(round(mean(valid_lai_init), digits=2)) m² m⁻²")

    valid_f0 = filter(!isnan, vec(f0))
    println("\nf0 (Zhou et al. spatially varying) statistics:")
    println("  Valid points: $(length(valid_f0))")
    println(
        "  Range: $(round(minimum(valid_f0), digits=3)) - $(round(maximum(valid_f0), digits=3))",
    )
    println("  Mean: $(round(mean(valid_f0), digits=3))")

    # Write output NetCDF
    println("\nWriting output to: $OUTPUT_FILE")
    ds_out = NCDataset(OUTPUT_FILE, "c")

    # Define dimensions
    defDim(ds_out, "lon", nlon)
    defDim(ds_out, "lat", nlat)

    # Define coordinate variables
    lon_var = defVar(ds_out, "lon", Float64, ("lon",))
    lon_var.attrib["units"] = "degrees_east"
    lon_var.attrib["long_name"] = "longitude"
    lon_var[:] = lon

    lat_var = defVar(ds_out, "lat", Float64, ("lat",))
    lat_var.attrib["units"] = "degrees_north"
    lat_var.attrib["long_name"] = "latitude"
    lat_var[:] = lat

    # Define data variables
    gsl_var = defVar(ds_out, "gsl", Float64, ("lon", "lat"))
    gsl_var.attrib["units"] = "days"
    gsl_var.attrib["long_name"] = "Growing Season Length"
    gsl_var.attrib["description"] = "GSL following Zhou et al. (2025): longest continuous above-0C period. Minimum GSL = $(MIN_GSL) days."
    gsl_var[:, :] = gsl

    a0_var = defVar(ds_out, "a0_annual", Float64, ("lon", "lat"))
    a0_var.attrib["units"] = "mol CO2 m^-2 yr^-1"
    a0_var.attrib["long_name"] = "Annual Potential GPP"
    a0_var.attrib["description"] = "Annual potential GPP computed with fAPAR=1 and beta=1 (no moisture stress). Last time point from simulation (after spin-up)."
    a0_var[:, :] = a0_out

    precip_var = defVar(ds_out, "precip_annual", Float64, ("lon", "lat"))
    precip_var.attrib["units"] = "mol H2O m^-2 yr^-1"
    precip_var.attrib["long_name"] = "Mean Annual Precipitation"
    precip_var.attrib["description"] = "Mean annual precipitation computed from monthly averages. Converted from kg m^-2 s^-1 to mol H2O m^-2 yr^-1 (1 mm = 55.51 mol H2O m^-2). Used for water limitation term (f0*P/A0) in LAI_max calculation following Zhou et al. (2025)."
    precip_var[:, :] = precip_annual

    vpd_var = defVar(ds_out, "vpd_gs", Float64, ("lon", "lat"))
    vpd_var.attrib["units"] = "Pa"
    vpd_var.attrib["long_name"] = "Growing Season Vapor Pressure Deficit"
    vpd_var.attrib["description"] = "Average VPD during growing season months (longest continuous above-0C period, Zhou et al. 2025). Used for water limitation term in LAI_max calculation."
    vpd_var[:, :] = vpd_gs

    lai_init_var = defVar(ds_out, "lai_init", Float64, ("lon", "lat"))
    lai_init_var.attrib["units"] = "m^2 m^-2"
    lai_init_var.attrib["long_name"] = "Initial Leaf Area Index"
    lai_init_var.attrib["description"] = "Initial LAI from MODIS satellite data (first timestep). Used to initialize the optimal LAI model instead of uniform value, reducing spin-up time."
    lai_init_var[:, :] = lai_init

    f0_var = defVar(ds_out, "f0", Float64, ("lon", "lat"))
    f0_var.attrib["units"] = "1"
    f0_var.attrib["long_name"] = "Fraction of precipitation for transpiration"
    f0_var.attrib["description"] = "Spatially varying f0 from Zhou et al. (2025). f0 = 0.65 * exp(-0.604 * ln^2(AI/1.9)) where AI is aridity index. Maximum value is 0.65. Used in water-limited fAPAR calculation for LAI_max."
    f0_var[:, :] = f0

    # Global attributes
    ds_out.attrib["title"] = "Initial Conditions for Optimal LAI Model"
    ds_out.attrib["source"] = "Computed from ClimaLand.jl optimal LAI simulation, ERA5 climate data, and MODIS LAI"
    ds_out.attrib["history"] = "Created by optimal_lai_inputs.jl"
    ds_out.attrib["references"] = "Zhou et al. (2025) Global Change Biology - GSL defined as days with T > 0C, water limitation via f0*P/A0 term"

    close(ds_out)
    println("Done!")
end

main()

create_artifact_guided(OUTPUT_DIR; artifact_name = basename(@__DIR__))
