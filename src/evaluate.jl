using DynamicExpressions: Expression, Node, AbstractOperatorEnum

function evaluate_exact(args...; kw...)
    mid.(_evaluate_exact(args...; kw...)[1])
end

function _evaluate_exact(expr::Expression{T}, x::AbstractArray{T}; kws...) where {T}
    _evaluate_exact(expr.tree, expr.metadata.operators, x; kws...)
end

function _evaluate_exact(
    TargetFloat::Type,
    tree::Node{I},
    ops::AbstractOperatorEnum,
    X::AbstractMatrix{I};
    init_precision::Int=800,
    max_precision::Int=2000,
) where {I<:Interval{BigFloat}}
    setprecision(init_precision) do
        hi_prec_intervals = evaluate(tree, ops, X)
        lo_prec_intervals = map(i -> convert(Interval{TargetFloat}, i), hi_prec_intervals)

        new_precision = init_precision * 2
        # not_thin = @. !isthin(low_prec_intervals)
        not_thin = map(i -> ulpdistance(bounds(i)...) <= 1, lo_prec_intervals)
        # @info "eval exact" init_precision length(not_thin) sum(not_thin) any(not_thin) hi_prec_intervals
        if new_precision <= max_precision && any(not_thin)
            better_hp, better_lp = _evaluate_exact(TargetFloat, tree, ops, X[:,not_thin]; init_precision=new_precision, max_precision=max_precision)
            hi_prec_intervals[not_thin] .= better_hp
            lo_prec_intervals[not_thin] .= better_lp
        end

        (hi_prec_intervals, lo_prec_intervals)
    end
end

function _evaluate_exact(
    tree::Node{T}, ops::AbstractOperatorEnum, X::AbstractMatrix{T}; kw...
) where {T<:AbstractFloat}
    I = Interval{BigFloat}
    _evaluate_exact(T, convert(Node{I}, tree), ops, convert(Matrix{I}, X); kw...)
end
function _evaluate_exact(tree::Node, ops::AbstractOperatorEnum, x::AbstractVector; kw...)
    (hi, lo) = _evaluate_exact(tree, ops, reshape(x, :, 1))
    (only(hi), only(lo))
end

function _evaluate_exact(
    TargetFloat::Type, f::Function, args::Number...; init_precision::Int=53, max_precision::Int=1500
)
    # compute interval for higher precision
    setprecision(init_precision) do
        arg_intervals = interval.(BigFloat.(args)) # do this only once!
        hi_prec_interval = f(arg_intervals...)
        lo_prec_interval = convert(Interval{TargetFloat}, hi_prec_interval)

        # check if we found an interval that only contains one number 𝑅𝑝(𝑦1) = 𝑦∗ = 𝑅𝑝(𝑦2)
        new_precision = init_precision * 2
        not_thin = ulpdistance(bounds(lo_prec_interval)...) <= 1
        if new_precision <= max_precision && not_thin
            _evaluate_exact(TargetFloat, f, args..., init_precision=new_precision, max_precision=max_precision)
        else
            (hi_prec_interval, lo_prec_interval)
        end
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
function lowlefteq(y::Tuple{T,Int}, x::AbstractVector) where {T}
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

function _evaluate_exact(regimes::Regimes, x::AbstractVector; kw...)
    @assert size(x, 1) == 1
    for regime in regimes.regs
        if contains(regime, x)
            return _evaluate_exact(regime.cand.expr, x; kw...)
        end
    end
    error("No applicable regime.")
end
function _evaluate_exact(regimes::Regimes, X::AbstractMatrix; kw...)
    map(c -> _evaluate_exact(regimes, c), eachcol(X))
end
