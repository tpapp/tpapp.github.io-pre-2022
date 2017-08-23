Pkg.clone("https://github.com/tpapp/MCMCDiagnostics.jl.git")
using MCMCDiagnostics
using StatsBase
using Distributions

"""
    zvalue(xs, x̄)

Return the normalized value (x̂-x̄)/MCMCSE(x). If the sampler is correct, follows a Normal(0,1) distribution.

MCMCSE(x) is the MCMC standard error, corrected by the effective sample size instead of the sample size.
"""
function zvalue(xs, x̄)
    ess = effective_sample_size(xs)
    x̂, σ = mean_and_std(xs; corrected = false)
    (x̂ - x̄) / (σ / √ess)
end

zrandn = [zvalue(randn(1000), 0.0) for _ in 1:1000000]

mean(abs.(zrandn) .≥ 5.0)
ccdf(Normal(0,1), 5.0)*2
