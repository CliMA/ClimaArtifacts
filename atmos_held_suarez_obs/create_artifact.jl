# Generate data and restart file for ClimaAtmos moist Held-Suarez perfect model calibration
# Before running this script, ensure that you have run `run_model.jl` 
# to produce the file `atmos_held_suarez_obs_artifact/truth_simulation/output_active/ta_60d_average.nc`.
# Since ClimaAtmos needs to run for 3000days to produce this, it is advisable to run this on a slurm cluster.

using ClimaArtifactsHelper
using ClimaAnalysis
using Statistics
import JLD2

const output_dir = basename(@__DIR__) * "_artifact"
const model_output_dir = joinpath(output_dir, "truth_simulation", "output_active")

if !isdir(model_output_dir)
    error(
        """The required directory $model_output_dir has not been created.\
        Please ensure that you have generated ClimaAtmos diagnostic output with `run_model.jl`"""
    )
end

const restart_file = "day200.0.hdf5"
const FILE_PATHS = (restart_file, "obs_mean.jld2", "obs_noise_cov.jld2")
const meters = 1.0
const days = 86400.0
if !all(isfile.(joinpath.(output_dir, FILE_PATHS)))
    @info "Artifact not found in $output_dir, reprocessing data from $model_output_dir"

    # Observation map: Take 60-day zonal average of air temperature at z = 242m
    simdir = SimDir(model_output_dir)
    ta = get(simdir; short_name = "ta", reduction = "average", period = "60d")

    # Take zonal average and slice for 242m altitude to get one sample every 60 days
    zonal_avg_temp_observations = slice(average_lat(average_lon(ta)), z = 242meters)

    # Sample observation is taken at 240 days. Needs to be a Vector{Float64} for EnsembleKalmanProcesses.jl
    # We only take one sample from our 1-dimensional data, so the observation is 1-length Vector{Float64}
    zonal_avg_at_240days = slice(zonal_avg_temp_observations, time = 240days)
    observation = Vector{Float64}(undef, 1)
    observation .= zonal_avg_at_240days.data
    # Covariance of the observational data. Needs to be a Matrix{Float64} for EnsembleKalmanProcesses.jl
    # Since our data is 1-dimensional, the covariance matrix is 1x1
    covariance = Matrix{Float64}(undef, 1, 1)
    covariance .= var(zonal_avg_temp_observations.data)

    # Save and cleanup
    JLD2.save_object(joinpath(output_dir, "obs_mean.jld2"), observation)
    JLD2.save_object(joinpath(output_dir, "obs_noise_cov.jld2"), covariance)
    mv(joinpath(model_output_dir, restart_file), joinpath(output_dir, restart_file))
    rm(model_output_dir, recursive=true)
end

create_artifact_guided(
    output_dir;
    artifact_name = basename(@__DIR__),
)
