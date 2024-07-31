using DynamicExpressions: parse_expression
using OptiFloat: Candidate, logsample, search_candidates!, infer_regimes, print_report, biterror
using Random

# FIXME: sometimes getting NaI in logsample
Random.seed!(1)

# Define expression. `features` contain a mapping from variable name to index in a sample
expr = :((b * (-1) - sqrt(b^2 - 4c)) / (2c))
T = Float16
dexpr, features = parse_expression(T, expr)

# Sample points to test expression. Each sample with have arity(dexpr) inputs.
# Only points that produce valid outputs are accepted as samples.
batchsize = 1000
points = logsample(dexpr, batchsize; eval_exact=false)

# Create first candidate and kick of optifloat main function
original = Candidate(dexpr, points)
candidates = [original]
search_candidates!(candidates, points) # repeat this call to further improve new candidates

# infer good regimes for input variable `b`
regimes = infer_regimes(candidates, features["b"], points)

print_report(original, regimes)

# Define an actual julia function for the new expression
improved_expr = OptiFloat.regimes_to_expr(regimes; interval_compatible=true)
improved = eval(improved_expr)

# Plot the results
let
    using Statistics: mean
    using Makie, CairoMakie
    using OptiFloat: default_splits
    fig = Figure()

    # sample new points and split them as necessary
    points = logsample(dexpr, 5000; eval_exact=false)
    for (v, i) in features
        splits = default_splits(points, i, 100)
        splits = collect.(zip(splits[1:(end - 1)], splits[2:end]))
        inputs = mean.(splits)
        orig, better = mapreduce((a, b) -> vcat.(a, b), splits) do (a, b)
            ps = filter(p -> a <= p[i] < b, eachcol(points))
            if length(ps) == 0
                T(NaN), T(NaN)
            else
                e_orig = biterror(dexpr, reduce(hcat, ps); accum=mean)
                cs = points[features["c"], :]
                bs = points[features["b"], :]
                e_better = mean(biterror.(T, improved, bs, cs))
                (e_orig, e_better)
            end
        end

        ax = Axis(
            fig[i, 1];
            xlabel=v,
            ylabel="Avg. Bits of Error",
            xscale=Makie.Symlog10(0),
            xticks=LogTicks(-200:1:200),
        )
        lines!(ax, inputs, orig; label="original")
        lines!(ax, inputs, better; label="improved")
        if i == 1
            axislegend(ax)
        end
    end
    fig
end
