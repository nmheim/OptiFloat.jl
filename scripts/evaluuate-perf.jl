using DynamicExpressions
using OptiFloat: evaluate_exact, evaluate, sample_bitpattern

T = Float16
xs = sample_bitpattern(T, T(0), floatmax(T), 1000) |> sort
kws = (; binary_operators=[-, +, /, ^, *], unary_operators=[sqrt], node_type=Node{T}, variable_names=["x"])

e1 = sqrt(x + 1) - sqrt(x)
e2 = 1 / (sqrt(x + 1) + sqrt(x))

