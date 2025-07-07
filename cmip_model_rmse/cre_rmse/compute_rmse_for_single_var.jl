import ClimaAnalysis
import NCDatasets
import Dates
import DataStructures: SortedDict

include("file_parser.jl")

"""
    compute_rmses(file::AbstractString)

Compute the global and seasonal RMSE of the file against observational data and
return the RMSEs as a vector.

The order of the vector is MAM, JJA, SON, DJF, and ANN RMSE.
"""
# TODO: Refactor this to take in OutputVars instead since it allows for the
# flexibility of manipulating the OutputVars beforehand
function compute_rmses(sim_file, obs_file, sim_short_name, obs_short_name, start_date, end_date)
    # Get the year as a datetime
    new_start_date = Dates.DateTime(start_date)
    # Load data
    sim_var = ClimaAnalysis.OutputVar(
        sim_file,
        sim_short_name,
        new_start_date = new_start_date,
        shift_by = Dates.firstdayofmonth,
    )


    obs_var = ClimaAnalysis.OutputVar(
        obs_file,
        obs_short_name,
        new_start_date = new_start_date,
        shift_by = Dates.firstdayofmonth,
    )

    if sim_short_name == "pr"
        @info "Number of positive numbers: $(count(>(0), sim_var.data))"
        @info "Number of negative numbers: $(count(<(0), sim_var.data))"
        val = 86400
        @info val
        sim_var = ClimaAnalysis.convert_units(
                    sim_var,
                    "mm/day",
                    conversion_function = x -> x .* Float32(val),
                )
    end

    # Window to get the dates we are interested in
    # Monthly averages are on the first day
    sim_var = ClimaAnalysis.window(
        sim_var,
        ClimaAnalysis.time_name(sim_var),
        left = start_date,
        right = end_date,
    )
    obs_var = ClimaAnalysis.window(
        obs_var,
        ClimaAnalysis.time_name(obs_var),
        left = start_date,
        right = end_date,
    )

    # Print dates
    @info "The dates of sim_var after loading the data as OutputVars"
    @info first(ClimaAnalysis.dates(sim_var)), last(ClimaAnalysis.dates(sim_var))

    # Check the bounds of sim_var
    if last(ClimaAnalysis.longitudes(sim_var)) > 180
        sim_var = ClimaAnalysis.Var.shift_longitude(sim_var, -180.0, 180.0)
    end
    if last(ClimaAnalysis.longitudes(obs_var)) > 180
        obs_var = ClimaAnalysis.Var.shift_longitude(obs_var, -180.0, 180.0)
    end
    # Resample to ensure grids are the same
    obs_var = ClimaAnalysis.resampled_as(obs_var, sim_var)

    # Get the seasons
    obs_var_seasons = ClimaAnalysis.split_by_season(obs_var)
    sim_var_seasons = ClimaAnalysis.split_by_season(sim_var)
    obs_var_seasons = (obs_var_seasons..., obs_var)
    sim_var_seasons = (sim_var_seasons..., sim_var)

    # Take time average
    time_avg_sim = ClimaAnalysis.average_time.(sim_var_seasons)
    time_avg_obs = ClimaAnalysis.average_time.(obs_var_seasons)

    return map(
        (sim_var, obs_var) -> ClimaAnalysis.global_rmse(sim_var, obs_var),
        time_avg_sim,
        time_avg_obs,
    )
end

"""
    find_correct_files(sim_data_dir, obs_data_file)

# TODO: Fix this!
Return a dictionary
mapping model name to a tuple of files containing
"""
function find_correct_files(sim_data_dir, short_name)
    # Get all file paths
    sim_data_files = [joinpath(root, file) for (root, _, files) in walkdir(sim_data_dir) for file in files]

    # Keep NetCDF files
    sim_data_files = filter(file -> occursin(".nc", file), sim_data_files)

    # Keep only files with "r1i1p1f1" which represents ensemble member identifier
    sim_data_files = filter(file -> occursin("r1i1p1f1", file), sim_data_files)

    # The grid for ICON-ESM-LR is unstructured and icosahedral which cannot be handled by
    # ClimaAnalysis
    bad_cases = ["ICON-ESM-LR"]
    sim_data_files = filter(file -> any(map(bad_case -> !occursin(bad_case, file), bad_cases)), sim_data_files)

    # Filter by short name
    sim_files = filter(file -> occursin("$(short_name)_", file), sim_data_files)
    sort!(sim_files, by = find_year)

    model_names = Set(find_model_name(sim_file) for sim_file in sim_files)

    # Create dicts mapping model names to file for each variable
    sim_var_dict = Dict(model_name => [sim_file for sim_file in sim_files if contain_model(sim_file, model_name)] for model_name in model_names)

    return sim_var_dict
end

if abspath(PROGRAM_FILE) == @__FILE__
    if length(ARGS) != 6
        error("Usage: julia compute_rmse.jl <Directory to the CMIP model outputs> <File to observation data> <Short name> <Start date> <End date>")
    end
    # "cmip_download_esgpull/data"
    sim_data_dir = ARGS[1]
    obs_data_file = ARGS[2]
    sim_short_name = ARGS[3]
    obs_short_name = ARGS[4]
    start_date = Dates.DateTime(ARGS[5])
    end_date = Dates.DateTime(ARGS[6])
    # obs_data_file = "/home/kphan/Desktop/work_tree/cre-calibration/cre_rmse_creation/ceres_obs_data/CERES_EBAF_Ed4.2_Subset_200003-201910.nc"

    # Map model name to corresponding files
    model_to_files_dict = find_correct_files(sim_data_dir, sim_short_name)

    # Map model name to RMSE
    # A sorted dictionary is used to sort the model names when producing the cvs file
    rmses_dict = SortedDict(k => compute_rmses(v, obs_data_file, sim_short_name, obs_short_name, start_date, end_date) for (k, v) in model_to_files_dict)

    open("$(sim_short_name)_amip_$(start_date)_$(end_date).csv", "w") do io
        write(io, "Model,DJF,MAM,JJA,SON,ANN\n")
        for (model_name, rmses) in rmses_dict
            # TODO: Update this since I should be able to control what the order should
            # be
            rmses = (rmses[4], rmses[1], rmses[2], rmses[3], rmses[5])
            rmses = string(rmses)
            rmses = rmses[2:length(rmses)-1] # remove parentheses
            write(io, "$model_name, $rmses\n")
        end
    end
end
