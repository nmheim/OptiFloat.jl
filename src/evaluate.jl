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

function evaluate_approx(expr, ops::OperatorEnum, x::AbstractVector)
    expr(reshape(x,1,:),ops)
end
function evaluate_approx(expr, ops::OperatorEnum, xs::AbstractMatrix)
    #vec(mapreduce(x -> evaluate_approx(expr, ops, x), hcat, eachcol(xs)))
    expr(xs, ops, early_exit=Val(false))
end

evaluate(args...) = evaluate_approx(args...)

struct Regimes{T}
    regs::T
end
function (regs::Regimes)(x::AbstractVector, ops::OperatorEnum)
    for regime in regs.regs
        if regime.low < x[1] <= regime.high
            return regime.expr(reshape(x,1,1), ops)
        end
    end
    error("No applicable regime.")
end
(regs::Regimes)(X::AbstractMatrix, ops::OperatorEnum) = mapreduce(c -> regs(c,ops), hcat, eachcol(X))

function evaluate_exact(regimes::Regimes, ops::OperatorEnum, x::AbstractVector; kw...)
    @assert size(x,1) == 1
    for regime in regimes.regs
        if regime.low < x[1] <= regime.high
            return evaluate_exact(regime.expr, ops, reshape(x,1,1); kw...)
        end
    end
    error("No applicable regime.")
end
evaluate_exact(regimes::Regimes, ops::OperatorEnum, X::AbstractMatrix; kw...) =
    mapreduce(c -> evaluate_exact(regimes,ops,c), hcat, eachcol(X))
