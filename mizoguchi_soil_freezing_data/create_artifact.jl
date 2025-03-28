using Downloads
using ClimaArtifactsHelper
using DelimitedFiles
using CairoMakie

"""
    plot(dataset_path)

Plot the freezing front for three representative times.
"""
function plot(dataset_path)
    ds = readdlm(dataset_path, ',')
    hours = ds[:, 1][2:end]
    vwc = ds[:, 2][2:end] ./ 100.0
    depth = ds[:, 3][2:end]

    mask_12h = hours .== 12
    mask_24h = hours .== 24
    mask_50h = hours .== 50

    fig = Figure(size = (1500, 500), fontsize = 36)
    ax1 = Axis(
        fig[1, 1],
        title = "12 hours",
        xlabel = L"θ_l + θ_i",
        ylabel = "Depth (m)",
        xgridvisible = false,
        ygridvisible = false,
        xticks = (0.2:0.1:0.4, ["0.2", "0.3", "0.4"]),
    )
    limits!(ax1, 0.2, 0.5, -0.2, 0.0)
    ax2 = Axis(
        fig[1, 2],
        title = "24 hours",
        xlabel = L"θ_l + θ_i",
        yticksvisible = false,
        yticklabelsvisible = false,
        xgridvisible = false,
        ygridvisible = false,
        xticks = (0.2:0.1:0.4, ["0.2", "0.3", "0.4"]),
    )
    limits!(ax2, 0.2, 0.5, -0.2, 0.0)
    ax3 = Axis(
        fig[1, 3],
        title = "50 hours",
        xlabel = L"θ_l + θ_i",
        yticksvisible = false,
        yticklabelsvisible = false,
        xgridvisible = false,
        ygridvisible = false,
        xticks = (0.2:0.1:0.4, ["0.2", "0.3", "0.4"]),
    )
    limits!(ax3, 0.2, 0.5, -0.2, 0.0)

    lines!(ax1, vwc[mask_12h], -depth[mask_12h], label = "", color = "orange")
    lines!(ax2, vwc[mask_24h], -depth[mask_24h], label = "", color = "orange")
    lines!(ax3, vwc[mask_50h], -depth[mask_50h], label = "Data", color = "orange")
    axislegend(ax3, position = :rb, framevisible = false)

    save("mizoguchi.png", fig)
end

const FILE_URL = "https://caltech.box.com/shared/static/3xbo4rlam8u390vmucc498cao6wmqlnd.csv"
const FILE_PATH = "mizoguchi_all_data.csv"

create_artifact_guided_one_file(FILE_PATH; artifact_name = basename(@__DIR__), file_url = FILE_URL)

plot(FILE_PATH)
