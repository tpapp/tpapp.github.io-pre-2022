f1(x) = ifelse(x ≥ 0, abs2(x+2), 1-x)
f2(x) = x ≥ 0 ? abs2(x+2) : 1-x

x = randn(1_000_000)
using BenchmarkTools
@belapsed f1.($x)
@belapsed f2.($x)

@code_native f1(1.0)
@code_native f2(1.0)
