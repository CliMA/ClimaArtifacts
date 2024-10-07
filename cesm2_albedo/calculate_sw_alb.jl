using NCDatasets

# Load the data
rsds_file = NCDataset("rsds_Amon_CESM2_historical_r1i1p1f1_gn_185001-201412.nc")
rsus_file = NCDataset("rsus_Amon_CESM2_historical_r1i1p1f1_gn_185001-201412.nc")

# Extract the data
rsds = rsds_file["rsds"][:, :, :]
rsus = rsus_file["rsus"][:, :, :]

# Create output file
sw_alb_file = NCDataset("sw_albedo_Amon_CESM2_historical_r1i1p1f1_gn_185001-201412_v2_no-nans.nc", "c")

# Define the dimensions
defDim(sw_alb_file, "lat", rsus_file.dim["lat"])
defDim(sw_alb_file, "bnds", rsus_file.dim["nbnd"])
defDim(sw_alb_file, "lon", rsus_file.dim["lon"])
defDim(sw_alb_file, "time", rsus_file.dim["time"])

# copy file attributes
for (attrib_name,attrib_value) in rsus_file.attrib
    sw_alb_file.attrib[attrib_name] = attrib_value
end

# for each var in the dataset, copy the needed attributes and set the others
sw_attrib = []
for (attrib_name,attrib_value) in rsus_file["rsus"].attrib
    if attrib_name != "coordinates"
        push!(sw_attrib, attrib_name => attrib_value)
    end
end

time_bnds_attrib = []
# skip the calendar and units attributes
no_copy_time_bnds = ["calendar", "units"]
for (attrib_name,attrib_value) in rsus_file["time_bnds"].attrib
    if !(attrib_name in no_copy_time_bnds)
        push!(time_bnds_attrib, attrib_name => attrib_value)
    end
end

time_attrib = []
# skip the calendar, title and type attributes
no_copy_time = ["calendar", "title", "type"]
for (attrib_name,attrib_value) in rsus_file["time"].attrib
    if !(attrib_name in no_copy_time)
        push!(time_attrib, attrib_name => attrib_value)
    end
end
push!(time_attrib, "calendar" => "365_day")

lon_bnds_attrib = []
for (attrib_name,attrib_value) in rsus_file["lon_bnds"].attrib
    if attrib_name != "units"
        push!(lon_bnds_attrib, attrib_name => attrib_value)
    end
end

lat_bnds_attrib = []
for (attrib_name,attrib_value) in rsus_file["lat_bnds"].attrib
    if attrib_name != "units"
        push!(lat_bnds_attrib, attrib_name => attrib_value)
    end
end

lon_attrib = []
# skip the title, type, valid_max and valid_min attributes
lon_lat_attrib_no_copy = ["title", "type", "valid_max", "valid_min"]
for (attrib_name,attrib_value) in rsus_file["lon"].attrib
    if !(attrib_name in lon_lat_attrib_no_copy)
        push!(lon_attrib, attrib_name => attrib_value)
    end
end
push!(lon_attrib, "long_name" => "longitude")

lat_attrib = []
for (attrib_name,attrib_value) in rsus_file["lat"].attrib
    if !(attrib_name in lon_lat_attrib_no_copy)
        push!(lat_attrib, attrib_name => attrib_value)
    end
end
push!(lat_attrib, "long_name" => "latitude")

# Calculate the shortwave albedo
sw_alb = ((x, y) -> y != 0.0 ? x/y : 1.0f0).(rsus, rsds)

# create the variables
defVar(sw_alb_file, "lat", rsus_file["lat"],  dimnames(rsus_file["lat"]); attrib = lat_attrib)
defVar(sw_alb_file, "lat_bnds", Float64.(rsus_file["lat_bnds"]), ("bnds", "lat"); attrib = lat_bnds_attrib)
defVar(sw_alb_file, "lon", rsus_file["lon"],  dimnames(rsus_file["lon"]); attrib = lon_attrib)
defVar(sw_alb_file, "lon_bnds", Float64.(rsus_file["lon_bnds"]), ("bnds", "lon"); attrib = lon_bnds_attrib)
defVar(sw_alb_file, "sw_alb", sw_alb, dimnames(rsus_file["rsus"]); fillvalue=1.0f0, attrib = sw_attrib)
defVar(sw_alb_file, "time", rsus_file["time"],  dimnames(rsus_file["time"]); attrib = time_attrib)
time_bnds = defVar(sw_alb_file, "time_bnds", rsus_file["time_bnds"], ("bnds", "time"); attrib = time_bnds_attrib)

close(sw_alb_file)
