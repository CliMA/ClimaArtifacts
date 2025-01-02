using NCDatasets
using Dates
using Statistics


ds = NCDataset("sw_albedo_Amon_CESM2_historical_r1i1p1f1_gn_185001-201412_v2_no-nans.nc")

# convert "no leap" dates to standard
dates = Dates.DateTime.(reinterpret.(Ref(NCDatasets.DateTimeStandard), ds["time"][:]))
latitude = ds["lat"][:]
longitude = ds["lon"][:]
sw_alb = Array(ds["sw_alb"])
months = month.(dates)
north = latitude .> 0.0
south = latitude .<= 0.0

# Get mean albedo over northern summer, replace missing with 1.o0
northern_summer = ((months .< 8) .& (months .> 4))
southern_summer = ((months .< 2) .| (months .>= 11))
northern_summer_albedo = sw_alb[:, :, northern_summer]
northern_summer_albedo[isnan.(northern_summer_albedo)] .= Float32(1.0)
northern_mean_summer_albedo = Statistics.mean(northern_summer_albedo, dims = 3)[:, :, 1]

# Get mean albedo over southern summer, replacing missing with 1.0
southern_summer_albedo = sw_alb[:, :, southern_summer]
southern_summer_albedo[isnan.(southern_summer_albedo)] .= Float32(1.0)
southern_mean_summer_albedo = Statistics.mean(southern_summer_albedo, dims = 3)[:, :, 1]

# Create summertime albedo with the northern value in the north, the southern value in the south.
summertime_albedo = zeros(Float32, size(southern_mean_summer_albedo))
summertime_albedo[:, north] .= northern_mean_summer_albedo[:, north]
summertime_albedo[:, south] .= southern_mean_summer_albedo[:, south]

# save this to a NC file
ds2 = NCDataset("bareground_albedo.nc", "c")
defDim(ds2, "lon", 288)
defDim(ds2, "lat", 192)
v = defVar(ds2, "sw_alb", Float32, ("lon", "lat"))
v[:, :] = summertime_albedo
v.attrib["units"] = ""
v.attrib["long_name"] = "Summertime albedo"
v.attrib["short_name"] = "sw_alb"
l = defVar(ds2, "lat", Float32, ("lat",))
l[:] = latitude
l.attrib["units"] = "degrees_north"
lo = defVar(ds2, "lon", Float32, ("lon",))
lo[:] = longitude
lo.attrib["units"] = "degrees_east"
close(ds2)
close(ds)
