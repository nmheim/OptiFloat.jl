using CairoMakie
using Printf
using Statistics: mean

function plot_accuracy(xs::Vector{<:Number}, as::Vector{<:Number}, nxticks=6)
    fig = Figure()
    n = length(xs)
    idx = 1:Int(div(n,nxticks)):n
    ax = Axis(fig[1, 1], xticks=(idx, [@sprintf("%.2e", n) for n in xs[idx]]), limits=(nothing, nothing, -0.1, 1.1))
    #ax = Axis(fig[1, 1])
    lines!(ax, as)
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
