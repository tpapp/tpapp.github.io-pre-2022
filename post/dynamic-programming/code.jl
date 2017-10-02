# Load the libraries (you need to clone some code, as the packages are not registered).
using ParametricFunctions       # unregistered, clone from repo
using ContinuousTransformations # unregistered, clone from repo
using EconFunctions             # unregistered, clone from repo
using Plots; gr()
using Parameters
using NLsolve

# It is useful to put model parameters in a single structure.

"""
Very simple (normalized) Ramsey model with isoelastic production
function and utility.
"""
@with_kw immutable RamseyModel{T}
    θ::T                        # IES
    α::T                        # capital share
    A::T                        # TFP
    ρ::T                        # discount rate
    δ::T                        # depreciation
end

"""
Residual of the Euler equation.
"""
function euler_residual(model::RamseyModel, c, k)
    @unpack θ, ρ, α, A, δ = model
    Fk = A*k^α - δ*k
    F′k = A*α*k^(α-1) - δ
    ck, c′k = c(ValuePartial(k))
    (c′k/ck)*(Fk-ck) - 1/θ*(F′k-ρ)
end

"Return the steady state capital and consumption for the model."
function steady_state(model::RamseyModel)
    @unpack α, A, ρ, δ = model
    k = ((δ+ρ)/(A*α))^(1/(α-1))
    c = A*k^α - δ*k
    k, c
end

model = RamseyModel(θ = 2.0, α = 0.3, A = 1.0, ρ = 0.02, δ = 0.05)

kₛ, cₛ = steady_state(model)

kdom = (0.5*kₛ)..(2*kₛ)

res = CollocationResidual(model, DomainTrans(kdom, Chebyshev(10)), euler_residual)

c_sol, o = solve_collocation(res, k->cₛ*k/kₛ; ftol=1e-10, method = :newton)

# plot the function
plot(c_sol, xlab = "k", ylab = "c(k)", legend = false)
scatter!([kₛ], [cₛ])

# plot the residual
plot(k->euler_residual(model, c_sol, k), linspace(kdom, 100),
     legend = false, xlab="k", ylab="Euler residual")
scatter!(zero, points(c_sol))
