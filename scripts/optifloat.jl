using OptiFloat: @optifloat, logsample
using IntervalArithmetic
using Random

# FIXME: sometimes getting NaI in logsample
Random.seed!(1)

original(b, c) = (b * (-1) - sqrt(b^2 - 4c)) / (2c)

arity = 2
T = Float16

# To use `improved` with `Interval`s as inputs we set `interval_compatible` to
# true. This is done such that we can pass it to biterror/evaluate_exact in the plotting code.
improved = @optifloat (b * (-1) - sqrt(b^2 - 4c)) / (2c) batchsize=1000 T=T interval_compatible=true

# sample new points
points = logsample(x -> original(x...), T, arity, 5000)

# Plot the results
let
    using Statistics: mean
    using Makie, CairoMakie
    using OptiFloat: default_splits, biterror

    fig = Figure()

    # b in first row, c in second
    features = Dict("b" => 1, "c" => 2)

    for (v, i) in features
        splits = default_splits(points, i, 100)
        splits = collect.(zip(splits[1:(end - 1)], splits[2:end]))
        inputs = mean.(splits)
        orig, better = mapreduce((a, b) -> vcat.(a, b), splits) do (a, b)
            ps = filter(p -> a <= p[i] < b, eachcol(points))
            if length(ps) == 0
                T(NaN), T(NaN)
            else
                ps = reduce(hcat, ps)
                args = [ps[i, :] for i in axes(ps, 1)]
                e_orig = mean(biterror.(T, original, args...))
                e_better = mean(biterror.(T, improved, args...))
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
