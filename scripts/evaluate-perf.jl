using DynamicExpressions
using OptiFloat: evaluate_exact, evaluate, logsample, evaluate_approx, biterror

T = Float16
kws = (; binary_operators=[-, +, /, ^, *], unary_operators=[sqrt], node_type=Node{T}, variable_names=["x"])
e1 = parse_expression(:(sqrt(x + 1) - sqrt(x)); kws...)
e2 = parse_expression(:(1 / (sqrt(x + 1) + sqrt(x))); kws...)
xs = logsample(e1, 1000)
xs = rand(T, 1, 8000)

ys = e1(xs; options=EvaluationOptions(early_exit=false))

using BenchmarkTools
@btime evaluate_approx($e1, $xs)
@btime e1($xs; options=EvaluationOptions(early_exit=false))
@btime e1($xs)

@profview for _ in 1:1000 evaluate_approx(e1, xs) end


bit
