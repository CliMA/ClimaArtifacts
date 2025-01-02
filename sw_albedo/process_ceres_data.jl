using NCDatasets

# Load the data
ceres_data = NCDataset("CERES_EBAF_Ed4.2_Subset_200003-201910.nc")

# Create output file
sw_alb_file = NCDataset("sw_albedo_Amon_CERES_EBAF_Ed4.2_Subset_200003-201910.nc", "c")

# Define the dimensions
defDim(sw_alb_file, "lat", ceres_data.dim["lat"])
defDim(sw_alb_file, "lon", ceres_data.dim["lon"])
defDim(sw_alb_file, "time", ceres_data.dim["time"])

# calculate new variables
sw_alb =
    calc_sw_alb.(
        ceres_data["sfc_sw_up_all_mon"][:, :, :],
        ceres_data["sfc_sw_down_all_mon"][:, :, :],
    )
sw_alb_clr =
    calc_sw_alb.(
        ceres_data["sfc_sw_up_clr_t_mon"][:, :, :],
        ceres_data["sfc_sw_down_clr_t_mon"][:, :, :],
    )

# create the variables
defVar(
    sw_alb_file,
    "lat",
    ceres_data["lat"],
    dimnames(ceres_data["lat"]);
    attrib = ceres_data["lat"].attrib,
)
defVar(
    sw_alb_file,
    "lon",
    ceres_data["lon"],
    dimnames(ceres_data["lon"]);
    attrib = ceres_data["lon"].attrib,
)
defVar(
    sw_alb_file,
    "time",
    ceres_data["time"],
    dimnames(ceres_data["time"]);
    attrib = ceres_data["time"].attrib,
)
defVar(
    sw_alb_file,
    "sw_alb",
    sw_alb[:, :, :],
    dimnames(ceres_data["sfc_sw_up_all_mon"]);
    attrib = ("long_name" => "Shortwave albedo", "short_name" => "sw_alb", "units" => ""),
)
defVar(
    sw_alb_file,
    "sw_alb_clr",
    sw_alb_clr[:, :, :],
    dimnames(ceres_data["sfc_sw_up_clr_t_mon"]);
    attrib = (
        "long_name" => "Shortwave albedo clear sky (for total region)",
        "short_name" => "sw_alb_clr",
        "units" => "",
    ),
)

close(sw_alb_file)
