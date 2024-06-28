using DynamicExpressions
using OptiFloat: evaluate_exact, evaluate, sample_bitpattern


T = Float16
#f(x) = sqrt(x+1) - sqrt(x)
#xs = sample_bitpattern(T, T(1), floatmax(T), 1000) |> sort
f(x) = -x - sqrt(x^2+1)
xs = sample_bitpattern(T, T(0), floatmax(T), 1000) |> sort

x = Node{T}(feature=1)
#ops = OperatorEnum(binary_operators=[-,+,/], unary_operators=[sqrt])
#expr = sqrt(x+1) - sqrt(x)
ops = OperatorEnum(binary_operators=[-,+,/,^,*], unary_operators=[sqrt])
expr = -1x - sqrt(x^2+1)


using Plots
plot(xs, f.(xs), xscale=:log10, label="approx f")
plot!(xs, evaluate(expr, ops, reshape(xs,1,:)), label="approx expr")
plot!(xs, evaluate_exact.(f, xs), label="exact f")
plot!(xs, evaluate_exact(expr, ops, reshape(xs,1,:)), label="exact expr")
