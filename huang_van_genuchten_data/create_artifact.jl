using Downloads
using ClimaArtifactsHelper
using DelimitedFiles
using CairoMakie

"""
    plot(dataset_path)

Plot the parameter data.
"""
function plot(dataset_path)
    parameter_data = readdlm(dataset_path, ',');

    depth = reverse(-parameter_data[1, :] .* 0.01) # convert to m
    ksat = reverse(parameter_data[6, :] .* 1 / 100.0 / 60.0) # convert cm/min to m/s
    vgα = reverse(parameter_data[4, :] .* 100 * 2) # they report αᵈ; αʷ = 2αᵈ. This experiment is for infiltration (wetting).
    vgn = reverse(parameter_data[5, :])
    residual_frac = reverse(parameter_data[2, :])
    porosity = reverse(parameter_data[3, :])

    fig = Figure(size = (1500, 1000), fontsize = 36)

    ax1 = Axis(
        fig[1, 1],
        xlabel = L"α (1/m)",
        ylabel = "Depth (m)",
        xgridvisible = false,
        ygridvisible = false,
    )
    ax2 = Axis(
        fig[1, 2],
        xlabel = L"k_{sat} (m/s)",
        ylabel = "Depth (m)",
        xgridvisible = false,
        ygridvisible = false,
    )
    ax3 = Axis(
        fig[2, 1],
        xlabel = L"n",
        ylabel = "Depth (m)",
        xgridvisible = false,
        ygridvisible = false,
    )
    ax4 = Axis(
        fig[2, 2],
        xlabel = "Porosity",
        ylabel = "Depth (m)",
        xgridvisible = false,
        ygridvisible = false,
    )

    lines!(ax1, vgα, depth, label = "", color = "orange")
    lines!(ax2, ksat, depth, label = "", color = "orange")
    lines!(ax3, vgn, depth, label = "", color = "orange")
    lines!(ax4, porosity, depth, label = "Data", color = "orange")
    axislegend(ax4, position = :rb, framevisible = false)

    save("huang.png", fig)
end

const FILE_URL = "https://caltech.box.com/shared/static/kbgxc8r2j6uzboxgg9h2ydi5145wdpxh.csv"
const FILE_PATH = "sv_62.csv"

create_artifact_guided_one_file(FILE_PATH; artifact_name = basename(@__DIR__), file_url = FILE_URL)

plot(FILE_PATH)
