using ClimaCore
import ClimaComms
ClimaComms.@import_required_backends
import SciMLBase
import ClimaTimeSteppers as CTS
using Plots
using Statistics
using DelimitedFiles

using ClimaLand
using ClimaLand.Soil
using ClimaLand.Domains: Column
import ClimaUtilities.OutputPathGenerator: generate_output_path

rmse(v1, v2) = sqrt(mean((v1 .- v2) .^ 2))

# Define simulation times
t_start = Float64(0)
dt = Float64(0.001)
t_end = Float64(1e6)

FT = Float64

stepper = ClimaLSM.RK4()
ode_algo = CTS.ExplicitAlgorithm(stepper)

# van Genuchten parameters for clay (from Bonan 2019 supplemental program 8.2)
ν = FT(0.495)
K_sat = FT(0.0443 / 3600 / 100) # m/s
vg_n = FT(1.43)
vg_α = FT(0.026 * 100) # inverse meters
θ_r = FT(0.124)
S_s = FT(1e-3) #inverse meters
hcm = vanGenuchten{FT}(; α = vg_α, n = vg_n)

zmax = FT(0)
zmin = FT(-0.5)
nelems = 50

params = Soil.RichardsParameters(;
    ν = ν,
    hydrology_cm = hcm,
    K_sat = K_sat,
    S_s = S_s,
    θ_r = θ_r,
)
soil_domain = Column(; zlim = (zmin, zmax), nelements = nelems)
sources = ()

# Set flux boundary conditions (used for calculating mass balance)
flux_in = FT(-1e-7)
top_bc = Soil.WaterFluxBC((p, t) -> flux_in)
flux_out = FT(0)
bot_bc = Soil.WaterFluxBC((p, t) -> flux_out)

boundary_fluxes = (; top = top_bc, bottom = bot_bc)

soil = Soil.RichardsModel{FT}(;
    parameters = params,
    domain = soil_domain,
    boundary_conditions = boundary_fluxes,
    sources = sources,
)

exp_tendency! = make_exp_tendency(soil)
set_initial_cache! = make_set_initial_cache(soil)
imp_tendency! = make_imp_tendency(soil)
jacobian! = make_jacobian(soil)

Y, p, coords = initialize(soil)
@. Y.soil.ϑ_l = FT(0.24)
set_initial_cache!(p, Y, FT(0.0))

jac_kwargs =
    (; jac_prototype = ImplicitEquationJacobian(Y), Wfact = jacobian!)

prob = SciMLBase.ODEProblem(
    CTS.ClimaODEFunction(T_exp! = exp_tendency!),
    Y,
    (t_start, t_end),
    p,
)
sol = SciMLBase.solve(prob, ode_algo; dt = dt, saveat = dt)

# Save flux BC reference solution artifact
savedir = ARGS[1]
soln_file = joinpath(savedir, "ref_soln_flux.csv")
open((soln_file), "w") do io
    writedlm(io, parent(sol.u[end].soil.ϑ_l), ',')
end

# TODO remove this after running once
    # Calculate water mass balance over entire simulation
    mass_end = sum(sol.u[end].soil.ϑ_l)
    mass_start = sum(sol.u[1].soil.ϑ_l)
    t_sim = sol.t[end] - sol.t[1]
    # Flux changes water content every timestep (assumes constant flux_in, flux_out)
    mass_change_exp = -(flux_in - flux_out) * t_sim
    mass_change_actual = mass_end - mass_start
    relerr = abs(mass_change_actual - mass_change_exp) / mass_change_exp
    @show relerr
    @assert relerr < FT(1e-9)
    mass_errors[i] = relerr


# Perform simulation with Dirichlet boundary conditions
top_state_bc = Soil.MoistureStateBC((p, t) -> ν - 1e-3)
flux_out = FT(0)
bot_flux_bc = Soil.WaterFluxBC((p, t) -> flux_out)
boundary_conds = (; top = top_state_bc, bottom = bot_flux_bc)

soil_dirichlet = Soil.RichardsModel{FT}(;
    parameters = params,
    domain = soil_domain,
    boundary_conditions = boundary_conds,
    sources = sources,
)

exp_tendency! = make_exp_tendency(soil_dirichlet)
set_initial_cache! = make_set_initial_cache(soil_dirichlet)
imp_tendency! = make_imp_tendency(soil_dirichlet)
jacobian! = make_jacobian(soil_dirichlet)
update_aux! = make_update_aux(soil_dirichlet)

rmses_dirichlet = Array{FT}(undef, length(dts))
mass_errors_dirichlet = Array{FT}(undef, length(dts))

Y, p, coords = initialize(soil_dirichlet)
@. Y.soil.ϑ_l = FT(0.24)
set_initial_cache!(p, Y, FT(0.0))

jac_kwargs =
    (; jac_prototype = ImplicitEquationJacobian(Y), Wfact = jacobian!)

prob = SciMLBase.ODEProblem(
    CTS.ClimaODEFunction(T_exp! = exp_tendency!),
    Y,
    (t_start, t_end),
    p,
)
# TODO remove saveat, sv after running once
saveat = Array(t_start:dt:t_end)
sv = (;
    t = Array{Int64}(undef, length(saveat)),
    saveval = Array{NamedTuple}(undef, length(saveat)),
)
cb = ClimaLand.NonInterpSavingCallback(sv, saveat)
sol = SciMLBase.solve(
    prob,
    ode_algo;
    dt = dt,
    callback = cb,
    adaptive = false,
    saveat = saveat,
)

# TODO remove this after running once
    # Calculate water mass balance over entire simulation
    # Because we use Backward Euler, compute fluxes at times[2:end]
    flux_in_sim =
        [parent(sv.saveval[k].soil.top_bc)[1] for k in 2:length(sv.saveval)]


    mass_end = sum(sol.u[end].soil.ϑ_l)
    mass_start = sum(sol.u[1].soil.ϑ_l)
    t_sim = sol.t[end] - sol.t[1]
    mass_change_exp = -(sum(flux_in_sim) * dt - flux_out * t_sim)
    mass_change_actual = mass_end - mass_start
    relerr = abs(mass_change_actual - mass_change_exp) / mass_change_exp
    @assert relerr < 1e11 * eps(FT)
    mass_errors_dirichlet[i] = relerr

# Save Dirichlet BC reference solution artifact
soln_file_dirichlet = joinpath(savedir, "ref_soln_dirichlet.csv")
open((soln_file_dirichlet), "w") do io
    writedlm(io, parent(sol.u[end].soil.ϑ_l), ',')
    writedlm(io, parent(sol.u[end].soil.ϑ_l), ',')
end
