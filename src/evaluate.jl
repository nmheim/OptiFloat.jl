function evaluate_exact(f, args::Union{<:Number,Int}...; init_precision::Int=53, max_precision::Int=1500)
    # compute interval for higher precision
    precision_interval = setprecision(init_precision) do
        intervals = interval.(BigFloat.(args))
        f(intervals...)
    end

    # check if we found an interval that only contains one number 𝑅𝑝(𝑦1) = 𝑦∗ = 𝑅𝑝(𝑦2)
    new_precision = init_precision * 2
    if isthin(precision_interval) || new_precision > max_precision
        setprecision(init_precision) do
            mid(precision_interval)
        end
    else
        evaluate_exact(f, args..., init_precision=new_precision, max_precision=max_precision)
    end
end

function evaluate_exact(expr::Expr, point::Union{<:Point,<:Batch}; kw...)
    g = lambdify(expr, keys(point)...)
    evaluate_exact.(g, values(point)...; kw...)
end
evaluate_exact(x::Symbol, p::Union{<:Point,<:Batch}; kw...) = p[x]
evaluate_exact(x::Number, p::Union{<:Point,<:Batch}; kw...) = x

Base.isfinite(x::Interval) = isbounded(x)
function evaluate_exact(expr::Node, ops::OperatorEnum, X::AbstractMatrix{Interval{BigFloat}}; init_precision::Int=53, max_precision::Int=1500)
    precision_intervals = setprecision(init_precision) do
        evaluate(expr, ops, X)
    end

    # check if we found an interval that only contains one number 𝑅𝑝(𝑦1) = 𝑦∗ = 𝑅𝑝(𝑦2)
    new_precision = init_precision * 2
    if all(isthin.(precision_intervals)) || new_precision > max_precision
        setprecision(init_precision) do
            mid.(precision_intervals)
        end
    else
        evaluate_exact(expr, ops, X, init_precision=new_precision, max_precision=max_precision)
    end
end

function evaluate_exact(expr::Node, ops::OperatorEnum, X::AbstractMatrix; kw...)
    evaluate_exact(
        convert(Node{Interval{BigFloat}},expr),
        ops,
        convert(Matrix{Interval{BigFloat}},X);
        kw...
    )
end
evaluate_exact(expr::Node, ops::OperatorEnum, x::AbstractVector; kw...) =
    only(evaluate_exact(expr, ops, reshape(x,:,1)))

function evaluate_approx(expr, ops::OperatorEnum, x::AbstractVector)
    expr(reshape(x,:,1),ops) |> only
end
function evaluate_approx(expr, ops::OperatorEnum, xs::AbstractMatrix)
    map(x -> evaluate_approx(expr, ops, x), eachcol(xs))
end

evaluate(args...) = evaluate_approx(args...)


struct Regime{T}
    expr::Node{T}
    low::T
    high::T
    "low index"
    li::Union{Int,Nothing}
    "high index"
    hi::Union{Int,Nothing}
end
Regime(expr, low, high) = Regime(expr, low, high, nothing, nothing)


struct Regimes{A<:AbstractVector{<:Regime}}
    regs::A
end
Regimes(rs::Tuple{E,A,B}...) where {A,B,E<:Node} = Regimes([Regime(args...) for args in rs])
function evaluate_approx(regs::Regimes, ops::OperatorEnum, x::AbstractVector)
    for regime in regs.regs
        if regime.low < x[1] <= regime.high
            #@info x[1] regime
            return evaluate_approx(regime.expr, ops, x)
        end
    end
    error("No applicable regime.")
end

Base.join(a::Regimes, b::Regimes) = Regimes(vcat(a.regs, b.regs))
Base.join(a::Regimes, r::Regime) = Regimes(vcat(a.regs, [r]))
function Base.show(io::IO, rs::Regimes{A}) where A
    println(io, "Regimes{$A}")
    for (i,r) in enumerate(rs.regs)
        if i==length(rs.regs)
            print(io, " ($(r.low), $(r.high))   : $(r.expr)")
        else
            println(io, " ($(r.low), $(r.high))   : $(r.expr)")
        end
    end
end



function evaluate_exact(regimes::Regimes, ops::OperatorEnum, x::AbstractVector; kw...)
    @assert size(x,1) == 1
    for regime in regimes.regs
        if regime.low < x[1] <= regime.high
            return evaluate_exact(regime.expr, ops, x; kw...)
        end
    end
    error("No applicable regime.")
end
evaluate_exact(regimes::Regimes, ops::OperatorEnum, X::AbstractMatrix; kw...) =
    map(c -> evaluate_exact(regimes,ops,c), eachcol(X))
