using DynamicExpressions
using OptiFloat: sample_bitpattern, evaluate_exact, logsample

T = Float16
orig_expr = :((-b - sqrt(b^2 - (4 * c))) / (2 * c))
candidate = :(((4c) / (sqrt(b ^ 2 - 4c) - b)) / (2c))
kws = (;
    variable_names=["c", "b"],
    binary_operators=[-, *, /, ^, +],
    unary_operators=[-, sqrt],
    node_type=Node{T},
)
e1 = parse_expression(orig_expr; kws...)
e2 = parse_expression(candidate; kws...)

points = logsample(e2, 1000; eval_exact=true)

y1 = e1(points; options=EvaluationOptions(early_exit=false))
y2 = e2(points; options=EvaluationOptions(early_exit=false))
labels = y2 .<= y1

let
    using CairoMakie
    using Makie
    (xp, yp) = eachrow(points)
    f = Figure()
    ax = Axis(f[1, 1]; yscale=Makie.Symlog10(1), xscale=Makie.Symlog10(1))
    scatter!(ax, xp[.!labels], yp[.!labels], label="$orig_expr")
    scatter!(ax, xp[labels], yp[labels], label="$candidate")
    axislegend(ax; position=:lb)
    f
end
