using NCDatasets
using ProgressMeter
using Dates
using Statistics
using Interpolations
using ClimaArtifactsHelper

include("download_utils.jl")
include("processing_utils.jl")

const DATADIR = ""
const CONSTS_URL = "https://goldsmr4.gesdisc.eosdis.nasa.gov/data/MERRA2_MONTHLY/M2C0NXASM.5.12.4/1980/MERRA2_101.const_2d_asm_Nx.00000000.nc4"
const full_ds_path = joinpath(DATADIR, "merra2_aerosols.nc")
const small_ds_path = joinpath(DATADIR, "merra2_aerosols_lowres.nc")

isdir(joinpath(DATADIR, "daily_data")) || mkdir(joinpath(DATADIR, "daily_data"))
isdir(joinpath(DATADIR, "monthly_data")) || mkdir(joinpath(DATADIR, "monthly_data"))
isdir(joinpath(DATADIR, "monthly_data_thinned")) ||
    mkdir(joinpath(DATADIR, "monthly_data_thinned"))

function download_range(downloads_dict, start_date, end_date)
    outfile_paths = Vector{String}()
    @showprogress for date = start_date:end_date
        if haskey(downloads_dict, date)
            url = downloads_dict[date]
            outfile_path = joinpath(DATADIR, "daily_data", "$(date).nc")
            isfile(outfile_path) || download_earthdata(url, outfile_path)
        end
    end
end


# dict from day to download url
downloads_dict = Dict()

open("download_urls.txt") do file
    for line in eachline(file)
        url_date = Dates.Date(match(r"(\d{8})\.nc", line)[1], "yyyymmdd")
        downloads_dict[url_date] = line
    end
end

download_range(downloads_dict, Dates.Date(1980, 1, 1), Dates.Date(2024, 11, 30))
@info "Downloaded all data"

z_min, z_max = 10.0, 80e3
exp_z_min, exp_z_max = Plvl(z_min), Plvl(z_max)
target_z = Plvl_inv.(range(exp_z_min, exp_z_max, NUM_Z))

download_earthdata(CONSTS_URL, "MERRA_CONSTS.nc")
ds_consts = NCDataset("MERRA_CONSTS.nc")
# grab a file to get target coordinates for interpolating consts file
ds_targ = NCDataset(joinpath(DATADIR, "daily_data", "2000-01-01.nc"))
target_lat = ds_targ["lat"][:]
target_lon = ds_targ["lon"][:]
close(ds_targ)
itp = extrapolate(
            interpolate((ds_consts["lon"], ds_consts["lat"]), ds_consts["PHIS"][:, :, 1],
                Gridded(Linear())), Flat())
lats = zeros(Float64, length(target_lon), length(target_lat))
lons = zeros(Float64, length(target_lon), length(target_lat))
for i = 1:length(target_lon)
    lats[i, :] .= target_lat
end
for i = 1:length(target_lat)
    lons[:, i] .= target_lon
end
surface_z = itp.(lons, lats) ./ 9.8

# no data for 2024/12
all_months = collect(Iterators.product(1:12, 1980:2024))[1:end-1]
unprocessed_months = filter(x -> !processing_completed(x[1], x[2]), all_months)
@info "Already processed $(round(Int64, 100* (1 -length(unprocessed_months)/ length(all_months))))% of months"
@showprogress for (month, year) in unprocessed_months
    file_paths = get_data_for_month(Dates.Date(year, month, 1))
    full_month_path = joinpath(DATADIR, "monthly_data", "$(year)_$(month).nc")
    length(file_paths) > 0 && create_monthly_mean_ds(file_paths, full_month_path, target_z, surface_z)
end

@assert all(processing_completed(x[1], x[2]) for x in all_months)
@info "All full resolution data converted to monthly means"

unprocessed_months =
    filter(x -> !processing_completed(x[1], x[2]; thinned = true), all_months)
@info "Already thinned and processed $(round(Int64, 100* (1 -length(unprocessed_months)/ length(all_months))))% of months"
@showprogress for (month, year) in unprocessed_months
    file_paths = get_data_for_month(Dates.Date(year, month, 1))
    thin_month_path = joinpath(DATADIR, "monthly_data_thinned", "$(year)_$(month).nc")
    length(file_paths) > 0 &&
        create_monthly_mean_ds(file_paths, thin_month_path, target_z, surface_z; small = true)
end

@assert all(processing_completed(x[1], x[2]; thinned = true) for x in all_months)
@info "All resolution data converted to thinned monthly means"

merge_ds(get_data_for_years(1980, 2024), full_ds_path)
@assert check_ds(full_ds_path) "Failed to merge full resolution data"
@info "Full resolution data merged"

merge_ds(get_data_for_years(1980, 2024; small = true), small_ds_path)
@assert check_ds(small_ds_path) "Failed to merge thinned resolution data"
@info "Thinned resolution data merged"

create_artifact_guided_one_file(full_ds_path; artifact_name = "merra2_aerosols")
create_artifact_guided_one_file(
    small_ds_path;
    artifact_name = "merra2_aerosols_lowres",
    append = true,
)
