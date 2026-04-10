using ClimaArtifactsHelper
using NCDatasets

dates_file = joinpath(@__DIR__, "dates.txt")
output_dir = "wxquest_initial_conditions_artifact"

if isdir(output_dir)
    @warn "$output_dir already exists. Existing content will be included in the artifact."
    @warn "Delete the directory and rerun if you want a clean download."
else
    mkdir(output_dir)
end

# Parse dates from dates.txt (format: "YYYY-MM-DD HH:MM", one per line)
dates = filter(!isempty, [strip(l) for l in readlines(dates_file) if !startswith(strip(l), "#")])

mktempdir(prefix="weatherquest_") do repo_dir
    run(`git clone --depth 1 git@github.com:CliMA/WeatherQuest.git $repo_dir`)
    get_ic = joinpath(repo_dir, "processing", "get_initial_conditions.py")

    @info "Downloading ERA5 initial conditions..."
    for entry in dates
        parts = split(entry)
        date, time = parts[1], length(parts) > 1 ? parts[2] : "00:00"
        @info "  $date $time"
        run(`python3 $get_ic
            --date $date --time $time
            --atmos-levels model
            --output-dir $output_dir`)
    end

    @info "Instantiating WeatherQuest Julia environment..."
    run(`julia --project=$repo_dir -e "using Pkg; Pkg.instantiate()"`)

    abs_output_dir = abspath(output_dir)

    @info "Generating atmosphere target grid file..."
    atmos_grid_file = joinpath(abs_output_dir, "atmos_grid.nc")
    NCDataset(atmos_grid_file, "c") do ds
        defDim(ds, "lon", 384)
        defDim(ds, "lat", 192)
        lon_var = defVar(ds, "lon", Float32, ("lon",),
            attrib = ["units" => "degrees_east", "axis" => "X",
                      "standard_name" => "longitude", "long_name" => "Longitude"])
        lat_var = defVar(ds, "lat", Float32, ("lat",),
            attrib = ["units" => "degrees_north", "axis" => "Y",
                      "standard_name" => "latitude", "long_name" => "Latitude"])
        lon_var[:] = Float32.(range(-180, 180, length = 384))
        lat_var[:] = Float32.(range(-90, 90, length = 192))
    end

    @info "Preprocessing initial conditions..."
    cd(joinpath(repo_dir, "processing")) do
        run(`julia --project=$repo_dir preprocessing.jl
            --start-datetime 20100101_0000
            --end-datetime 20101001_0000
            --interval 3months
            --data-dir $abs_output_dir
            --atmos-grid-file $atmos_grid_file`)
    end
end

@info "Creating artifact..."
create_artifact_guided(output_dir; artifact_name = basename(@__DIR__))
