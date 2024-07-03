using DynamicExpressions: Expression, Node, OperatorEnum


evaluate_exact(expr::Expression{T}, x::AbstractArray{T}) where T =
    evaluate_exact(expr.tree, expr.metadata.operators, x)

function evaluate_exact(tree::Node{I}, ops::OperatorEnum, X::AbstractMatrix{I}; init_precision::Int=53, max_precision::Int=1500) where {I<:Interval{BigFloat}}
    precision_intervals = setprecision(init_precision) do
        evaluate(tree, ops, X)
    end

    # check if we found an interval that only contains one number 𝑅𝑝(𝑦1) = 𝑦∗ = 𝑅𝑝(𝑦2)
    new_precision = init_precision * 2
    if all(isthin.(precision_intervals)) || new_precision > max_precision
        setprecision(init_precision) do
            mid.(precision_intervals)
        end
    else
        evaluate_exact(tree, ops, X, init_precision=new_precision, max_precision=max_precision)
    end
end

function evaluate_exact(tree::Node{T}, ops::OperatorEnum, X::AbstractMatrix{T}; kw...) where {T<:AbstractFloat}
    I = Interval{BigFloat}
    evaluate_exact(convert(Node{I}, tree), ops, convert(Matrix{I},X); kw...)
end
evaluate_exact(tree::Node, ops::OperatorEnum, x::AbstractVector; kw...) = 
    only(evaluate_exact(tree, ops, reshape(x,:,1)))

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

evaluate(args...) = evaluate_approx(args...)
evaluate_approx(expr::Expression, x::AbstractArray) = evaluate_approx(expr.tree, expr.metadata.operators, x)
evaluate_approx(tree::Node, ops::OperatorEnum, x::AbstractVector) =
    tree(reshape(x,:,1), ops) |> only
evaluate_approx(tree::Node, ops::OperatorEnum, xs::AbstractMatrix) =
    map(x -> evaluate_approx(tree, ops, x), eachcol(xs))


struct Regime{T}
    expr::Expression{T}
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
Regimes(rs::Tuple{E,A,B}...) where {A,B,E<:Expression} = Regimes([Regime(args...) for args in rs])

function evaluate_approx(regs::Regimes, x::AbstractVector)
    for regime in regs.regs
        if regime.low < x[1] <= regime.high
            return evaluate_approx(regime.expr, x)
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

function evaluate_exact(regimes::Regimes, x::AbstractVector; kw...)
    @assert size(x,1) == 1
    for regime in regimes.regs
        if regime.low < x[1] <= regime.high
            return evaluate_exact(regime.expr, x; kw...)
        end
    end
    error("No applicable regime.")
end
evaluate_exact(regimes::Regimes, X::AbstractMatrix; kw...) =
    map(c -> evaluate_exact(regimes,c), eachcol(X))
