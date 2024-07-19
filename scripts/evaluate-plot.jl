using DynamicExpressions
using OptiFloat: evaluate_exact, evaluate, sample_bitpattern

T = Float16
xs = sample_bitpattern(T, T(0), floatmax(T), 1000) |> sort

x = Node{T}(; feature=1)
ops = OperatorEnum(; binary_operators=[-, +, /, ^, *], unary_operators=[sqrt])

e1 = sqrt(x + 1) - sqrt(x)
e2 = 1 / (sqrt(x + 1) + sqrt(x))

let
    using CairoMakie
    f = Figure()
    kws = (;)
    a1 = Axis(f[1, 1]; xscale=log10, title="$e1")
    scatter!(
        a1, xs, evaluate(e1, ops, reshape(xs, 1, :)); color=1, colorrange=(1, 10), colormap=:tab10
    )
    lines!(
        a1,
        xs,
        evaluate_exact(e1, ops, reshape(xs, 1, :));
        color=2,
        colorrange=(1, 10),
        colormap=:tab10,
    )

    a2 = Axis(f[1, 2]; xscale=log10, title="$e2")
    scatter!(
        a2,
        xs,
        evaluate(e2, ops, reshape(xs, 1, :));
        color=1,
        colorrange=(1, 10),
        colormap=:tab10,
        label="asdf",
    )
    lines!(
        a2,
        xs,
        evaluate_exact(e2, ops, reshape(xs, 1, :));
        color=2,
        colorrange=(1, 10),
        colormap=:tab10,
    )

    f
end
