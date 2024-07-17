using BenchmarkTools
using DynamicExpressions: Node, parse_expression
using OptiFloat: evaluate_approx, evaluate_exact, biterror, logsample
const SUITE = BenchmarkGroup()

T = Float16
kws = (;
    binary_operators=[-, +, /, ^, *],
    unary_operators=[sqrt],
    node_type=Node{T},
    variable_names=["x"],
)
expr = parse_expression(:(sqrt(x + 1) - sqrt(x)); kws...)
xs = logsample(expr, 10000)

SUITE["evaluate_approx"] = @benchmarkable evaluate_approx($expr, $xs)
SUITE["evaluate_exact"] = @benchmarkable evaluate_exact($expr, $xs)
SUITE["biterror"] = @benchmarkable biterror($expr, $expr, $xs)
