library(rstan)
rstan_options(auto_write = TRUE)
options(mc.cores = parallel::detectCores())

chain <- function(K) stan("code.stan", iter = 1000, chains = 1, data = list(K))
zvalues <- function(ch) {
    s = summary(ch)$summary
    z = s[, "mean"] / (s[, "sd"] / sqrt(s[, "n_eff"]))
    z[names(z) != "lp__"]
}
ch0 = chain(10)
get_adaptation_info(ch0)
get_sampler_params(ch0)

zmax = replicate(100, max(zvalues(chain(10))))
max(zmax)
