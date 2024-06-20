using CairoMakie
using Printf
using Statistics: mean

function plot_accuracy(xs::Vector{<:Number}, ys::Vector{<:Number})
    fig = Figure()
    m = xs |> eltype |> maxintfloat |> log10
    xticks = [10^i for i in 1:floor(m)]
    xticks = vcat(-xticks, xticks)
	xticklabels = [@sprintf("%.e",x) for x in xticks]
    ax = Axis(fig[1, 1], xscale=Makie.Symlog10(1), xticks=(xticks, xticklabels), xlimits=(minimum(xs), maximum(xs)))
    lines!(ax, xs, ys)
    fig
end

function plot_accuracy(xs::Vector{<:Number}, yss::Vector{<:Vector{<:Number}}, nxticks=6)
    yss = [filter(isfinite, ys) for ys in yss]
    ys = mean.(yss)
    fig = Figure()
    n = length(xs)
    idx = 1:Int(div(n,nxticks)):n
    ax = Axis(fig[1, 1], xticks=(idx, [@sprintf("%.2e", n) for n in xs[idx]]), limits=(nothing, nothing, -0.1, 1.1))
    #ax = Axis(fig[1, 1])
    for (x,y) in zip(1:n, yss)
        if x%3==0
            scatter!(ax, [x for _ in 1:length(y)], y, color=(:blue, 0.5), alpha=0.5, marker=:x)
        end
    end
    lines!(ax, ys)
    fig
end
