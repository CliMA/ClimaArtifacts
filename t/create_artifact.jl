using Downloads
using ClimaArtifactsHelper
using Dates
using NCDatasets
using Statistics
using StatsBase

const OUTPUT_DIRECTORY = "tropomi_SIF_monthly_avg_allsky"
const BASE_FILE_PATH = "https://ftp.sron.nl/open-access-data-2/TROPOMI/tropomi/sif/v2.1/l2b/"
const DATE_LOWER_BOUND = Date(2018,5) #No data availible until this date

const IQR_MULT_SPACE = 1.5 # IQR Multiplier # MUST BE FLOAT
const IQR_MULT_TIME = 3.0 # IQR Multiplier # IQR Multiplier # MUST BE FLOAT
const RES = 1 # bin size in lon/lat degrees
const MIN_COUNT_SPACE = 10
const MIN_COUNT_TIME = 8

years = ["2020", "2021"]
months = ["01","02","03","04","05","06","07","08","09","10","11","12"]

job_id = parse(Int, ENV["SLURM_ARRAY_TASK_ID"])
year = years[job_id]

days = ["01", "02", "03", "04", "05", "06", "07", "08", "09", "10",
        "11", "12", "13", "14", "15", "16", "17", "18", "19", "20",
        "21", "22", "23", "24", "25", "26", "27", "28", "29", "30",
        "31"]

lats = -90:RES:89
lons = -180:RES:179

gridval = [Float64[] for _ in 1:length(lons), _ in 1:length(lats)] # non averaged values
griderror = [Float64[] for _ in 1:length(lons), _ in 1:length(lats)] # non averaged errors

valid_day_values = [Float64[] for _ in 1:length(lons), _ in 1:length(lats)] #all daily values
valid_day_errors = [Float64[] for _ in 1:length(lons), _ in 1:length(lats)] #all daily errors

new_data = [Float64[] for _ in 1:length(lons), _ in 1:length(lats)]
new_data_err = [Float64[] for _ in 1:length(lons), _ in 1:length(lats)]

#used for spatial_clipping, called per day
function spatial_clipping!(
    new_data::Matrix{Vector{Float64}},
    new_data_err::Matrix{Vector{Float64}},
    data::Matrix{Vector{Float64}},
    data_err::Matrix{Vector{Float64}},
    mult::Float64 = IQR_MULT_SPACE
)

    for i in 1:size(data, 1)
        for j in 1:size(data, 2)

            empty!(new_data[i,j])
            empty!(new_data_err[i,j])

            isempty(data[i,j]) && continue

            clean_data = copy(data[i,j])
            clean_data_err = copy(data_err[i,j])

            isempty(filter(!isnan, clean_data)) && continue

            i_q_r = iqr(filter(!isnan, clean_data))

            lower_val = percentile(filter(!isnan, clean_data), 25) - (mult *i_q_r)
            upper_val = percentile(filter(!isnan, clean_data), 75) + (mult *i_q_r)
            for k in eachindex(clean_data)
                if (clean_data[k] < lower_val) || (clean_data[k] > upper_val)
                    clean_data[k] = NaN 
                    clean_data_err[k] = NaN 
                end
            end
                        # Enforce MIN_COUNT
            if count(!isnan, clean_data) < MIN_COUNT_SPACE
                clean_data .= NaN
                clean_data_err  .= NaN
            end

            new_data[i,j] = clean_data
            new_data_err[i,j] = clean_data_err
        end
    end
    return new_data, new_data_err
end

#used for temporal_clipping, per month
function temporal_clipping!(
    data::Matrix{Vector{Float64}},
    data_err::Matrix{Vector{Float64}},
    mult::Float64 = IQR_MULT_TIME
)

    new_data_month = [Float64[] for _ in 1:length(lons), _ in 1:length(lats)]
    new_data_err_month = [Float64[] for _ in 1:length(lons), _ in 1:length(lats)]

    for i in 1:size(data, 1)
        for j in 1:size(data, 2)
            
            isempty(data[i,j]) && continue

            clean_data = copy(data[i,j])
            clean_data_err = copy(data_err[i,j])

            isempty(filter(!isnan, clean_data)) && continue

            i_q_r = iqr(filter(!isnan, clean_data))

            lower_val = percentile(filter(!isnan, clean_data), 25) - (mult *i_q_r)
            upper_val = percentile(filter(!isnan, clean_data), 75) + (mult *i_q_r)
            for k in eachindex(clean_data)
                if (clean_data[k] < lower_val) || (clean_data[k] > upper_val)

                    clean_data[k] = NaN 
                    clean_data_err[k] = NaN

                end
            end
                        # Enforce MIN_COUNT
            if count(!isnan, clean_data) < MIN_COUNT_TIME
                clean_data .= NaN
                clean_data_err  .= NaN
            end

            new_data_month[i,j] = clean_data
            new_data_err_month[i,j] = clean_data_err
        end
    end
    return new_data_month, new_data_err_month
end

if isdir(OUTPUT_DIRECTORY)
    @warn "$OUTPUT_DIRECTORY already exists. Content will end up in the artifact and may be overwritten."
    @warn "Abort this calculation, unless you know what you are doing."
else
    mkdir(OUTPUT_DIRECTORY)
end 



file = joinpath(OUTPUT_DIRECTORY,"binned_$(year)_full_run.nc") #new file name
ds_new = NCDataset(file,"c") #create new .nc file

defDim(ds_new, "lon", length(lons))
defDim(ds_new, "lat", length(lats))
defDim(ds_new, "time", 12)

lon = defVar(ds_new, "lon", Float32, ("lon",))
lon[:] = lons
lon.attrib["units"] = "degrees"

lat = defVar(ds_new, "lat", Float32, ("lat",))
lat[:] = lats
lat.attrib["units"] = "degrees"

sif_var = defVar(ds_new, "SIF_Corr_743", Float32, ("lon","lat","time"))
sif_var.attrib["units"] = "mW/m2/sr/nm"
sif_var.attrib["comments"] = "SIF_Corr_743 from TROPOSIF binned"

err_var = defVar(ds_new, "SIF_ERROR_743", Float32, ("lon","lat","time"))
err_var.attrib["units"] = "mW/m2/sr/nm"
err_var.attrib["comments"] = "SIF_ERROR_743 from TROPOSIF binned"

year_int = parse(Int, year)
dates = [DateTime(year_int, m, 15, 0, 0) for m in 1:12]
reference_date = DateTime(year_int, 1, 1, 0, 0, 0)

time_var = defVar(ds_new, "time", Int64, ("time",))
time_var[:] = [Dates.value(d - reference_date) ÷ 1000 for d in dates]

ref_str = Dates.format(reference_date, "yyyy-mm-dd HH:MM:SS")
time_var.attrib["units"] = "seconds since $ref_str"

for month in months

    date = Date(match(r"\d{4}-\d{2}", basename(year*"-"*month)).match) # date for comparison

    if (date >= DATE_LOWER_BOUND)

        foreach(empty!, valid_day_values)
        foreach(empty!, valid_day_errors)

        for day in days # iterate through days

            download_url = BASE_FILE_PATH*year*"/"*month*"/TROPOSIF_L2B_"*year*"-"*month*"-"*day*".nc" #url to access dataset
            println("Downloading $(year)-$(month)-$(day)...")
            #flush(stdout)

            path = nothing
            
            try
                path = Downloads.download(download_url, progress = download_rate_callback())
                #ds = NCDataset(Downloads.download(download_url, progress = download_rate_callback())) # read dataset

                println("Downloaded: $path")
                println("Size: $(filesize(path)) bytes")
                #flush(stdout)

                ds = NCDataset(path)

                prod = ds.group["PRODUCT"] # get product

                lat = prod["latitude"][:]
                lon = prod["longitude"][:]
                sif = prod["SIF_Corr_743"][:]
                error = prod["SIF_ERROR_743"][:]

                close(ds)

                foreach(empty!, gridval)
                foreach(empty!, griderror)

                for i in eachindex(sif)

                    isnan(sif[i]) && continue

                    ix = mod(floor(Int, (lon[i] + 180) / RES),360) + 1
                    iy = floor(Int, (lat[i] + 90) / RES) + 1

                    if 1 <= ix <= length(lons) && 1 <= iy <= length(lats)
                        push!(gridval[ix, iy], sif[i]) 
                        push!(griderror[ix,iy], error[i]) # used in harmonic average
                    end
                end

                clean_gridval, clean_griderror = spatial_clipping!(new_data, new_data_err, gridval, griderror)

                append!.(valid_day_values, clean_gridval)
                append!.(valid_day_errors, clean_griderror)

                println("\n $(year)-$(month)-$(day) downloaded \n")
            catch err
                println("\n $(year)-$(month)-$(day) not downloaded \n")
                #flush(stdout)
                showerror(stdout, err, catch_backtrace())
            finally
                if path !== nothing && isfile(path)
                    rm(path, force=true)
                end
            end
        end

        monthly_grid, monthly_err = temporal_clipping!(valid_day_values,valid_day_errors)

        month_idx = parse(Int, month)

        sif_var[:,:,month_idx] .= map(v -> (valid = filter(!isnan, v); isempty(valid) ? NaN : mean(valid)), monthly_grid)

        err_var[:, :, month_idx] .= map(v -> (valid = filter(!isnan, v); isempty(valid) ? NaN : 1 / sqrt(sum((1 ./ valid).^2))), monthly_err)

    end 
end
close(ds_new)


create_artifact_guided(OUTPUT_DIR; artifact_name = basename(@__DIR__), append = true)