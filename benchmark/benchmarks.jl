using Pkg
Pkg.update()
Pkg.add(url = "https://github.com/JuliaSymbolics/Metatheory.jl", rev="ale/3.0")
Pkg.add(url = "https://github.com/nmheim/DynamicExpressions.jl", rev="nh/early-exit")
Pkg.dev(path = "..")

using BenchmarkTools
using DynamicExpressions: Node, parse_expression
using OptiFloat: evaluate_approx, evaluate_exact, biterror, logsample
const SUITE = BenchmarkGroup()

SUITE["ParametricSpeciesDictUnion"] = BenchmarkGroup()

T = Float16
kws = (; binary_operators=[-, +, /, ^, *], unary_operators=[sqrt], node_type=Node{T}, variable_names=["x"])
expr = parse_expression(:(sqrt(x + 1) - sqrt(x)); kws...)
xs = logsample(e1, 10000)

SUITE["evaluate_approx"] = @benchmarkable evaluate_approx($e1, $xs)
SUITE["evaluate_exact"] = @benchmarkable evaluate_exact($e1, $xs)
SUITE["biterror"] = @benchmarkable biterror($e1, $e1, $xs)

[ Info:     Creating temporary environment at /var/folders/qc/0bylx5y131z9pggm5w86jgnm0000gn/T/jl_j3y688.
