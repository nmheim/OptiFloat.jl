using DynamicExpressions: Expression, Node, AbstractOperatorEnum

function evaluate_exact(expr::Expression{T}, x::AbstractArray{T}) where {T}
    evaluate_exact(expr.tree, expr.metadata.operators, x)
end

function evaluate_exact(
    tree::Node{I},
    ops::AbstractOperatorEnum,
    X::AbstractMatrix{I};
    init_precision::Int=53,
    max_precision::Int=1500,
) where {I<:Interval{BigFloat}}
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
        evaluate_exact(tree, ops, X; init_precision=new_precision, max_precision=max_precision)
    end
end

function evaluate_exact(
    tree::Node{T}, ops::AbstractOperatorEnum, X::AbstractMatrix{T}; kw...
) where {T<:AbstractFloat}
    I = Interval{BigFloat}
    evaluate_exact(convert(Node{I}, tree), ops, convert(Matrix{I}, X); kw...)
end
function evaluate_exact(tree::Node, ops::AbstractOperatorEnum, x::AbstractVector; kw...)
    only(evaluate_exact(tree, ops, reshape(x, :, 1)))
end

function evaluate_exact(
    f, args::Union{<:Number,Int}...; init_precision::Int=53, max_precision::Int=1500
)
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
        evaluate_exact(f, args...; init_precision=new_precision, max_precision=max_precision)
    end
end

evaluate(args...) = evaluate_approx(args...)
function evaluate_approx(expr::Expression, x::AbstractArray)
    evaluate_approx(expr.tree, expr.metadata.operators, x)
end
function evaluate_approx(tree::Node, ops::AbstractOperatorEnum, x::AbstractVector)
    only(evaluate_approx(tree, ops, reshape(x, :, 1)))
end
function evaluate_approx(tree::Node, ops::AbstractOperatorEnum, xs::AbstractMatrix)
    tree(xs, ops; options=EvaluationOptions(early_exit=false))
end

struct Regime{T<:AbstractFloat,C<:Candidate,V<:Union{<:AbstractVector{T},Tuple{T,Int}},I<:Union{Int,Nothing}}
    cand::C
    low::V
    high::V
    "low index"
    li::I
    "high index"
    hi::I
end
Regime(expr, low::Vector, high::Vector) = Regime(expr, low, high, nothing, nothing)
Regime(expr, low::Number, high::Number) = Regime(expr, [low], [high], nothing, nothing)

struct Regimes{A<:AbstractVector{<:Regime}}
    regs::A
end
Regimes(rs::Tuple...) = Regimes([Regime(args...) for args in rs])

lowleft(x::AbstractVector, y::AbstractVector) = all(x .< y)
function lowleft(x::AbstractVector, y::Tuple{T,Int}) where {T}
    (val, index) = y
    x[index] < val
end
function lowleft(y::Tuple{T,Int}, x::AbstractVector) where {T}
    (val, index) = y
    val < x[index]
end
function lowleft(x::Tuple{T,Int}, y::Tuple{T,Int}) where {T}
    (xval, xindex) = x
    (yval, yindex) = y
    if xindex == yindex
        xval < yval
    else
        error("Splits are not on same index.")
    end
end

lowlefteq(x::AbstractVector, y::AbstractVector) = all(x .<= y)
function lowlefteq(x::AbstractVector, y::Tuple{T,Int}) where {T}
    (val, index) = y
    x[index] <= val
end
function lowleft(y::Tuple{T,Int}, x::AbstractVector) where {T}
    (val, index) = y
    val <= x[index]
end

Base.contains(x, point::AbstractVector, y) = lowleft(x, point) && lowlefteq(point, y)
Base.contains(r::Regime, x::AbstractVector) = contains(r.low, x, r.high)
Base.contains(rs::Regimes, x::AbstractVector) = any(contains(r, x) for r in rs.regs)

function evaluate_approx(regs::Regimes, x::AbstractVector)
    for regime in regs.regs
        if contains(regime, x)
            return evaluate_approx(regime.cand.cand_expr, x)
        end
    end
    error("No applicable regime.")
end
function evaluate_approx(regs::Regimes, ops::AbstractOperatorEnum, x::AbstractVector)
    for regime in regs.regs
        if contains(regime, x)
            return evaluate_approx(regime.cand.cand_expr.tree, ops, x)
        end
    end
    error("No applicable regime.")
end
function evaluate_approx(regimes::Regimes, X::AbstractMatrix; kw...)
    map(c -> evaluate_approx(regimes, c), eachcol(X))
    #xs = eachcol(X)
    #Xs = map(reg.regs) do reg
    #    filter(p -> contains(reg, p), xs)
    #end

end

Base.join(a::Regimes, b::Regimes) = Regimes(vcat(a.regs, b.regs))
Base.join(a::Regimes, r::Regime) = Regimes(vcat(a.regs, [r]))
function Base.show(io::IO, rs::Regimes{A}) where {A}
    println(io, "Regimes:")
    for (i, r) in enumerate(rs.regs)
        if i == length(rs.regs)
            print(io, "  ($(r.low), $(r.high))   : $(string_tree(r.cand.cand_expr))")
        else
            println(io, "  ($(r.low), $(r.high))   : $(string_tree(r.cand.cand_expr))")
        end
    end
end

function evaluate_exact(regimes::Regimes, x::AbstractVector; kw...)
    @assert size(x, 1) == 1
    for regime in regimes.regs
        if contains(regime, x)
            return evaluate_exact(regime.cand.expr, x; kw...)
        end
    end
    error("No applicable regime.")
end
#function evaluate_exact(regimes::Regimes, ops::AbstractOperatorEnum, x::AbstractVector; kw...)
#    @assert size(x,1) == 1
#    for regime in regimes.regs
#        if contains(regime, x)
#            return evaluate_exact(regime.expr, ops, x; kw...)
#        end
#    end
#    error("No applicable regime.")
#end
function evaluate_exact(regimes::Regimes, X::AbstractMatrix; kw...)
    map(c -> evaluate_exact(regimes, c), eachcol(X))
end
