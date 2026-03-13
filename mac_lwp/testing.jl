using NCDatasets
using Test

const mac_lwp_dir = joinpath(@__DIR__, "mac_lwp_files")
const processed_file = joinpath(mac_lwp_dir, "mac_lwp.nc")
const orig_files = sort(
    filter(f -> endswith(f, ".nc4"), readdir(mac_lwp_dir, join = true)),
    by = f -> parse(Int, match(r"(\d{4})_v1", basename(f)).captures[1]),
)

@testset "mac_lwp postprocessed file" begin
    NCDataset(processed_file) do ds
        @testset "variables present" begin
            @test haskey(ds, "cloudlwp")
            @test haskey(ds, "cloudlwp_error")
            @test haskey(ds, "time")
        end

        @testset "cloudlwp" begin
            v = ds["cloudlwp"]
            data = Array(v)
            # No Union{Missing, ...} — all missing replaced with NaN
            @test eltype(data) == Union{Missing, Float32}
            # 29 years × 12 months = 348 time steps
            @test size(data, 3) == 348
            @test ndims(data) == 3
        end

        @testset "cloudlwp_error" begin
            v = ds["cloudlwp_error"]
            data = Array(v)
            @test eltype(data) == Union{Missing, Float32}
            @test size(data, 3) == 348
            @test ndims(data) == 3
        end

        @testset "time" begin
            t = Array(ds["time"])
            @test length(t) == 348
            @test t[1] == ds["time"][1]
        end
    end
end

@testset "original downloaded files" begin
    @test length(orig_files) == 29  # 1988-2016

    for file in orig_files
        NCDataset(file) do ds
            @testset "$(basename(file))" begin
                @test haskey(ds, "cloudlwp")
                @test haskey(ds, "cloudlwp_error")

                @testset "cloudlwp" begin
                    data = Array(ds["cloudlwp"])
                    @test eltype(data) <: Union{Missing, Float32}
                    @test size(data, 3) == 12  # 12 months per file
                    @test ndims(data) == 3
                end

                @testset "cloudlwp_error" begin
                    data = Array(ds["cloudlwp_error"])
                    @test eltype(data) <: Union{Missing, Float32}
                    @test size(data, 3) == 12
                    @test ndims(data) == 3
                end
            end
        end
    end
end

@testset "postprocessed matches originals" begin
    NCDataset(processed_file) do ds
        processed_lwp = Array(ds["cloudlwp"])
        processed_err = Array(ds["cloudlwp_error"])

        for (i, file) in enumerate(orig_files)
            NCDataset(file) do orig_ds
                orig_lwp = coalesce.(Array(orig_ds["cloudlwp"]), NaN32)
                orig_err = coalesce.(Array(orig_ds["cloudlwp_error"]), NaN32)

                t_start = (i - 1) * 12 + 1
                t_end = i * 12
                @info file
                @info t_start
                @info t_end

                @testset "$(basename(file)) matches processed slice" begin
                    @test isapprox(
                        processed_lwp[:, :, t_start:t_end],
                        orig_lwp;
                        nans = true,
                    )
                    @test isapprox(
                        processed_err[:, :, t_start:t_end],
                        orig_err;
                        nans = true,
                    )
                end
            end
        end
    end
end
