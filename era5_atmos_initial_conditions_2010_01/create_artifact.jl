# Generates the `era5_atmos_initial_conditions_2010_01` artifact: the ERA5 atmospheric state at 2010-01-01 00:00 UTC
# that ClimaAtmos's `WeatherModel` initial condition reads, rewritten losslessly with compression.
#
# The input is `era5_init_processed_internal_20100101_0000.nc` from the `wxquest_initial_conditions` artifact, whose
# recipe builds it from ERA5 model-level data.
#
# Run with:
#   cd era5_atmos_initial_conditions_2010_01 && julia --project=. create_artifact.jl
# `WXQUEST_INITIAL_CONDITIONS_DIR` sets where the input is read from (by default the `wxquest_initial_conditions`
# artifact, located through an `Overrides.toml`), and `ARTIFACT_OUTPUT_DIR` where the artifact folder is written.

using Artifacts: artifact_path
using NCDatasets: NCDataset
using NetCDF_jll: nccopy
using ClimaArtifactsHelper

const artifact_name = basename(@__DIR__)
const file_name = "era5_init_processed_internal_20100101_0000.nc"
# git-tree-sha1 of `wxquest_initial_conditions` in the ClimaAtmos and ClimaCoupler Artifacts.toml files
const wxquest_initial_conditions = Base.SHA1("85b1e3654fb88f19a715ea6c235e1d66f254d2e6")
const input_directory = get(ENV, "WXQUEST_INITIAL_CONDITIONS_DIR", artifact_path(wxquest_initial_conditions))
const input_path = joinpath(input_directory, file_name)
const output_directory = get(ENV, "ARTIFACT_OUTPUT_DIR", joinpath(@__DIR__, artifact_name * "_artifact"))
const output_path = joinpath(output_directory, file_name)

isfile(input_path) || error("$input_path not found; build it with the wxquest_initial_conditions recipe")
if !isfile(output_path)
    mkpath(output_directory)
    # Shuffle and deflate in chunks spanning whole columns
    run(`$(nccopy()) -k nc4 -s -d 4 -c z/467,lat/16,lon/16 -m 2G -h 2G $input_path $output_path`)
end

# Every variable and attribute is unchanged (`isequal`, because the fill value is NaN)
NCDataset(input_path) do original
    NCDataset(output_path) do compressed
        @assert keys(compressed) == keys(original)
        @assert isequal(Dict(compressed.attrib), Dict(original.attrib))
        for name in keys(original)
            @assert isequal(Array(compressed[name].var), Array(original[name].var)) "values of $name changed"
            @assert isequal(Dict(compressed[name].attrib), Dict(original[name].attrib)) "attributes of $name changed"
        end
    end
end

create_artifact_guided(output_directory; artifact_name)
