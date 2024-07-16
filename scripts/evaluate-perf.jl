using DynamicExpressions
using OptiFloat: evaluate_exact, evaluate, logsample, evaluate_approx, biterror

T = Float16
kws = (; binary_operators=[-, +, /, ^, *], unary_operators=[sqrt], node_type=Node{T}, variable_names=["x"])
e1 = parse_expression(:(sqrt(x + 1) - sqrt(x)); kws...)
e1 = parse_expression(:(sqrt(-(sqrt((x ^ 2.0) - 1.0) + x)) * sqrt(-(sqrt((x ^ 2.0) - 1.0) + x))); kws...)
e1 = parse_expression(:(sqrt(-x) * sqrt(-x)); kws...)
e1 = parse_expression(:(sqrt(x)); kws...)
e2 = parse_expression(:(1 / (sqrt(x + 1) + sqrt(x))); kws...)
xs = logsample(e1, 1000)
xs = rand(T, 1, 8000)

ys = e1(xs; options=EvaluationOptions(early_exit=false))
evaluate_exact(e1, xs; init_precision=53)

using BenchmarkTools
@btime evaluate_approx($e1, $xs)
@btime evaluate_exact($e1, $xs; init_precision=1000)
@benchmark evaluate_exact($e1, $xs; init_precision=1000)
@btime e1($xs; options=EvaluationOptions(early_exit=false))
@btime e1($xs)

@profview for _ in 1:1000 evaluate_approx(e1, xs) end
@profview for _ in 1:10 evaluate_exact(e1, xs; init_precision=1000) end


@btime biterror($e1,$e1,$xs)
