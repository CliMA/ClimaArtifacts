import ClimaAnalysis
import NCDatasets
import Dates
import DataStructures: SortedDict

include("file_parser.jl")

"""
    compute_rmse(file::AbstractString)

Compute the global and seasonal RMSE of the file against observational data and
return the RMSEs as a vector.

The order of the vector is MAM, JJA, SON, DJF, and ANN RMSE.
"""
function compute_cre_rmses(sim_data_file_rsut, sim_data_file_rsutcs, obs_data_file::AbstractString, year)
    # Get the year as a datetime
    new_start_date = Dates.DateTime(year)
    # Check dates with sim-data_file_rsut and sim_data_file_rsutcs
    for sim_data_file in (sim_data_file_rsut, sim_data_file_rsutcs)
        sim_ds = NCDatasets.NCDataset(sim_data_file)
        times = sim_ds["time"][:]
        if !(Dates.year(first(times)) <= year <= Dates.year(last(times)))
            error("The year $year cannot be found in $sim_data_file")
        end
        close(sim_ds)
    end

    # Load data
    sim_var_rsut = ClimaAnalysis.OutputVar(
        sim_data_file_rsut,
        "rsut",
        new_start_date = new_start_date,
        shift_by = Dates.firstdayofmonth,
    )
    sim_var_rsutcs = ClimaAnalysis.OutputVar(
        sim_data_file_rsutcs,
        "rsutcs",
        new_start_date = new_start_date,
        shift_by = Dates.firstdayofmonth,
    )
    ceres_var_rsut = ClimaAnalysis.OutputVar(
        obs_data_file,
        "toa_sw_all_mon",
        new_start_date = new_start_date,
        shift_by = Dates.firstdayofmonth,
    )
    ceres_var_rsutcs = ClimaAnalysis.OutputVar(
        obs_data_file,
        "toa_sw_clr_t_mon",
        new_start_date = new_start_date,
        shift_by = Dates.firstdayofmonth,
    )

    # Check for units
    for var in (sim_var_rsut, sim_var_rsutcs, ceres_var_rsut, ceres_var_rsutcs)
        ClimaAnalysis.units(var) == "W m-2" || error("Unit is not W m-2")
    end

    # Compute CRE
    sim_var = sim_var_rsutcs - sim_var_rsut
    obs_var = ceres_var_rsutcs - ceres_var_rsut

    # Set units since ClimaAnalysis binary operations do not keep units
    sim_var = ClimaAnalysis.set_units(sim_var, "W m^-2")
    obs_var = ClimaAnalysis.set_units(obs_var, "W m^-2")

    # Window to get only 2010
    # Monthly averages are on the first day
    sim_var = ClimaAnalysis.window(
        sim_var,
        ClimaAnalysis.time_name(sim_var),
        left = Dates.DateTime(year, 1, 1),
        right = Dates.DateTime(year, 12, 1),
    )
    obs_var = ClimaAnalysis.window(
        obs_var,
        ClimaAnalysis.time_name(obs_var),
        left = Dates.DateTime(year, 1, 1),
        right = Dates.DateTime(year, 12, 1),
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

Find the files for `rsut` and `rsutcs` that contain the year 2010. Return a dictionary
mapping model name to a tuple of files containing `rsut` and `rsutcs`.
"""
function find_correct_files(sim_data_dir)
    # Get all file paths
    sim_data_files = [joinpath(root, file) for (root, _, files) in walkdir(sim_data_dir) for file in files]

    # Keep NetCDF files
    sim_data_files = filter(file -> occursin(".nc", file), sim_data_files)

    # Keep only files with "r1i1p1f1" which represents ensemble member identifier
    sim_data_files = filter(file -> occursin("r1i1p1f1", file), sim_data_files)

    # Keep only files that contain the year 2010
    sim_data_files = filter(file -> contain_year(file, Dates.Date(2010)), sim_data_files)

    # The grid for ICON-ESM-LR is unstructured and icosahedral which cannot be handled by
    # ClimaAnalysis
    bad_cases = ["ICON-ESM-LR"]
    sim_data_files = filter(file -> any(map(bad_case -> !occursin(bad_case, file), bad_cases)), sim_data_files)

    rsutcs_files = filter(file -> occursin("rsutcs_", file), sim_data_files)
    rsut_files = filter(file -> occursin("rsut_", file), sim_data_files)

    # Create dicts mapping model names to file for each variable
    rsut_dict = Dict(find_model_name(rsut_file) => rsut_file for rsut_file in rsut_files)
    rsutcs_dict = Dict(find_model_name(rsutcs_file) => rsutcs_file for rsutcs_file in rsutcs_files)

    available_model_names = intersect(keys(rsut_dict), keys(rsutcs_dict))
    rsut_rsutcs_dict = Dict(model_name => (rsut_dict[model_name], rsutcs_dict[model_name]) for model_name in available_model_names)
    return rsut_rsutcs_dict
end

if abspath(PROGRAM_FILE) == @__FILE__
    if length(ARGS) < 2
        error("Usage: julia compute_rmse.jl <Directory to the CMIP model outputs> <File to observation data>")
    end
    # "cmip_download_esgpull/data"
    sim_data_dir = ARGS[1]
    obs_data_file = "/home/kphan/Desktop/work_tree/cre-calibration/cre_rmse_creation/ceres_obs_data/CERES_EBAF_Ed4.2_Subset_200003-201910.nc"

    # Map model name to tuple of rsut file and rsutcs file
    rsut_rsutcs_dict = find_correct_files(sim_data_dir)

    # Map model name to RMSE
    # A sorted dictionary is used to sort the model names when producing the cvs file
    rmses_dict = SortedDict(k => compute_cre_rmses(v..., obs_data_file, 2010) for (k, v) in rsut_rsutcs_dict)

    # Write to a CSV and record the model names and RMSEs
    open("cre_rmse_amip_cre_amip_2010.csv", "w") do io
        write(io, "Model,DJF,MAM,JJA,SON,ANN\n")
        for (model_name, rmses) in rmses_dict
            rmses = (rmses[4], rmses[1], rmses[2], rmses[3], rmses[5])
            rmses = string(rmses)
            rmses = rmses[2:length(rmses)-1] # remove parentheses
            write(io, "$model_name, $rmses\n")
        end
    end
end
