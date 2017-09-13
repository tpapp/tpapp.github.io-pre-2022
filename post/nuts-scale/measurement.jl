using DiffBase
using Parameters
# libraries below need to be cloned from https://github.com/tpapp
using DynamicHMC
using MCMCDiagnostics
using DiffWrappers

# consistent sampling
const RNG = srand(UInt32[0x19c57cdc, 0xcf2abfb8, 0xb2075646, 0xcf63ab58])

"""
    GradMvNormal(n)

Returns a callable that provides the value and the gradient for the log density
(w/o constants) of a standard multivariate normal with dimension `n`.
"""
struct GradMvNormal{T}
    n::Int
    result::T
end

GradMvNormal(n::Int) = GradMvNormal(n, DiffBase.GradientResult(zeros(n)))

Base.length(ℓ::GradMvNormal) = ℓ.n

function (ℓ::GradMvNormal)(x)
    @unpack n, result = ℓ
    result.value = -0.5*sum(abs2, x)
    @. result.derivs[1] = -x
    result
end

"""
    BareMvNormal()

Callable which returns the log density for a standard multivariate normal (w/o
constants). Dimension is determined by the argument length.
"""
struct BareMvNormal end

(::BareMvNormal)(x) = -0.5*sum(abs2, x)

"""
    time_per_effective_sample(ℓ; [N], [rng])

Time per effective sample when sampling from ℓ, incl tuning.
"""
function time_per_effective_sample(ℓ; N = 2000, rng = RNG)
    println("benchmarking with dimension $(length(ℓ))")
    tic()
    sample, _ = NUTS_tune_and_mcmc(rng, ℓ, N)
    walltime = toq()
    ESS = mean(mapslices(effective_sample_size, variable_matrix(sample), 1))
    walltime / ESS
end

ns = @. round(Int, 1.15^(17:40))
walltimes_grad = map(time_per_effective_sample ∘ GradMvNormal, ns)
walltimes_AD = map(ns) do n
    time_per_effective_sample(ForwardGradientWrapper(BareMvNormal(), n))
end

# drop first, to disregard compilation time
ns = ns[2:end]
walltimes_grad = walltimes_grad[2:end]
walltimes_AD = walltimes_AD[2:end]

using Plots
plt = plot(log2.(ns), log2.(walltimes_grad); # xscale = :log2, yscale = :log2,
           label = "w/ gradient", legend = :topleft,
           xlab = "dimension (log2)", ylab = "wall time (log2, incl tuning)")
plot!(plt, log2.(ns), log2.(walltimes_AD), label = "ForwardDiff")
savefig(plt, "timeperESvsN.svg")

"crude regression"
function slope(x, y, discard = 0)
    x = x[(1+discard):end]
    y = y[(1+discard):end]
    ([ones(length(x)) x] \ y)[2]
end

slope(log2.(ns), log2.(walltimes_grad), findlast(log2.(ns) .< 5.0))
slope(log2.(ns), log2.(walltimes_AD), findlast(log2.(ns) .< 5.0))
