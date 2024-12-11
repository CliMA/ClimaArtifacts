using ClimaCore
import OrdinaryDiffEq as ODE
import ClimaTimeSteppers as CTS
using Plots
using Statistics
using DelimitedFiles
using ArtifactWrappers
using ClimaLSM
using ClimaLSM.Soil
using ClimaLSM.Domains: Column
FT = Float64
rmse(v1, v2) = sqrt(mean((v1 .- v2) .^ 2))

# Set up timestepping
stepper = CTS.RK4()
ode_algo = CTS.ExplicitAlgorithm(stepper)
t_start = FT(0)
t_end = FT(1e6)
dt = Float64(0.01) # Run with very small dt for accurate results

# van Genuchten parameters for clay (from Bonan 2019 supplemental program 8.2)
ν = FT(0.495)
K_sat = FT(0.0443 / 3600 / 100) # m/s
vg_n = FT(1.43)
vg_α = FT(0.026 * 100) # inverse meters
θ_r = FT(0.124)
S_s = FT(1e-3) #inverse meters
hcm = vanGenuchten(; α = vg_α, n = vg_n)
zmax = FT(0)
zmin = FT(-0.5)
nelems = 50
params = Soil.RichardsParameters{FT, typeof(hcm)}(ν, hcm, K_sat, S_s, θ_r)
soil_domain = Column(; zlim = (zmin, zmax), nelements = nelems)
sources = ()
# Set flux boundary conditions (used for calculating mass balance)
flux_in = FT(-1e-7)
top_bc = Soil.FluxBC((p, t) -> eltype(t)(flux_in))
flux_out = FT(0)
bot_bc = Soil.FluxBC((p, t) -> eltype(t)(flux_out))
boundary_fluxes = (; top = (water = top_bc,), bottom = (water = bot_bc,))
soil = Soil.RichardsModel{FT}(;
    parameters = params,
    domain = soil_domain,
    boundary_conditions = boundary_fluxes,
    sources = sources,
)
exp_tendency! = make_exp_tendency(soil)

# Initialize model and set ICs
Y, p, coords = initialize(soil)
@. Y.soil.ϑ_l = FT(0.24)
prob = ODE.ODEProblem(
    CTS.ClimaODEFunction(T_exp! = exp_tendency!),
    Y,
    (t_start, t_end),
    p,
)
sol = ODE.solve(prob, ode_algo; dt = dt, saveat = t_end)

# Save Flux BC reference solution artifact (using small dt)
savedir = joinpath("..", ARGS[1])
soln_file = joinpath(savedir, "ref_soln_flux.csv")
open(soln_file, "w") do io
    writedlm(io, parent(sol.u[end].soil.ϑ_l), ',')
end


# Perform simulation with Dirichlet boundary conditions
top_state_bc = MoistureStateBC((p, t) -> eltype(t)(ν - 1e-3))
flux_out = FT(0)
bot_flux_bc = Soil.FluxBC((p, t) -> eltype(t)(flux_out))
boundary_conds =
    (; top = (water = top_state_bc,), bottom = (water = bot_flux_bc,))
soil_dirichlet = Soil.RichardsModel{FT}(;
    parameters = params,
    domain = soil_domain,
    boundary_conditions = boundary_conds,
    sources = sources,
)
exp_tendency! = make_exp_tendency(soil_dirichlet)

# Initialize model and set ICs
Y, p, coords = initialize(soil_dirichlet)
@. Y.soil.ϑ_l = FT(0.24)
prob = ODE.ODEProblem(
    CTS.ClimaODEFunction(T_exp! = exp_tendency!),
    Y,
    (t_start, t_end),
    p,
)
sol = ODE.solve(prob, ode_algo; dt = dt, saveat = t_end)

# Save Dirichlet BC reference solution artifact (using small dt)
soln_file_dirichlet = joinpath(savedir, "ref_soln_dirichlet.csv")
open(soln_file_dirichlet, "w") do io
    writedlm(io, parent(sol.u[end].soil.ϑ_l), ',')
end
