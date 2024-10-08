_inttype(::Type{Float16}) = Int16
_inttype(::Type{Float32}) = Int32
_inttype(::Type{Float64}) = Int64

default_accum(x) = mean(x)

function ulpdistance(a::F, b::F) where {F<:AbstractFloat}
    T = _inttype(F)
    a == b && return zero(T)
    isnan(a) || isnan(b) && return typemax(T)
    isinf(a) || isinf(b) && return typemax(T)

    a_int = reinterpret(T, a)
    b_int = reinterpret(T, b)

    (a_int < 0) != (b_int < 0) && return typemax(T)

    return abs(a_int - b_int)
end

"""
    biterror(x::T, y::T) where {T}

The `biterror` is defined as the logarithm of the ULP-distance (unit at the last
place) `biterror(x,y) = log2(ulpdistance(x,y))`. For the example above to
approximately 11 bits:

```julia-repl
julia> using OptiFloat
julia> f(x) = sqrt(x+1) - sqrt(x)
julia> g(x) = 1 / (sqrt(x+1) + sqrt(x))
julia> x = Float16(3730)
julia> OptiFloat.biterror(f(x), g(x))
```
"""
function biterror(x::T, y::T) where {T}
    ulp = ulpdistance(x, y)
    T(ulp == 0 ? 0 : log2(ulp))
end

function biterror(TargetFloat::Type, f::Function, args...)
    y_exact = evaluate_exact(TargetFloat, f, args...)
    y_approx = try
        y = f(args...)
        @assert y isa TargetFloat
        y
    catch e
        if e isa DomainError
            TargetFloat(NaN)
        else
            rethrow(e)
        end
    end

    biterror(y_approx, convert(TargetFloat, y_exact))
end

function biterror(
    orig, target, ops::AbstractOperatorEnum, X::AbstractMatrix{T}; accum=default_accum
) where {T}
    errs = try
        y_approx = evaluate_approx(orig, ops, X)
        y_exact = evaluate_exact(target, ops, X; init_precision=800)
        biterror.(y_approx, convert(Vector{T}, y_exact))
    catch e
        if e isa DomainError
            @debug "Assigning maximal error to $orig because of DomainError"
            fill(log2(floatmax(T)), size(X, 2))
        else
            rethrow(e)
        end
    end
    accum(errs)
end
function biterror(reg::PiecewiseRegime, X::AbstractArray; accum=default_accum)
    mapreduce(vcat, reg.regs) do r
        mask = [contains(r, p) for p in eachcol(X)]
        r.cand.errors[mask, :]
    end |> accum
end
function biterror(expr::Expression, target::Expression, X::AbstractArray; kw...)
    biterror(expr.tree, target.tree, expr.metadata.operators, X; kw...)
end
function biterror(expr::Expression, X::AbstractArray; kw...)
    biterror(expr.tree, expr.tree, expr.metadata.operators, X; kw...)
end

function biterrorscore(expr, x::AbstractArray{T}; kw...) where {T<:AbstractFloat}
    err = biterror(expr, x; kw...)
    score = 1 - (err / (sizeof(T) * 8))
    convert(T, score)
end

function all_operators(expr::Expr)
    ops = if iscall(expr)
        [operation(expr); reduce(vcat, all_operators.(arguments(expr)))]
    else
        []
    end
    unique(ops)
end
function all_operators(r::RewriteRule)
    unique([all_operators(r.lhs_original); all_operators(r.rhs_original)])
end
all_operators(x::Vector) = unique(mapreduce(all_operators, vcat, x))
all_operators(x) = []

function all_subexpressions(expr::Union{Expr,Node})
    subs = if iscall(expr)
        vcat([expr], reduce(vcat, all_subexpressions.(arguments(expr))))
    else
        [expr]
    end
    unique(subs)
end
all_subexpressions(x) = [x]
function all_subexpressions(expr::Expression)
    trees = all_subexpressions(expr.tree)
    [Expression(t, expr.metadata) for t in trees]
end

maximum_precision(::Int) = 0
maximum_precision(x::AbstractFloat) = precision(x)
maximum_precision(fs::Vector) = maximum(maximum_precision.(fs))

convert_args(T::Type{<:AbstractFloat}, arg::Number) = convert(T, arg)
convert_args(T::Type{<:AbstractFloat}, args::Vector) = convert_args.(T, args)

"""
    function local_biterror(
        tree::Node{T},
        ops::AbstractOperatorEnum,
        X::AbstractMatrix{T};
        accum=default_accum
    ) where {T}

Compute the error of the root node in `tree`. The children are evaluated
exactly, such that only the error of the root node is returned.
[`local_biterrors`](@ref) computes the local error for all nodes in the tree.
"""
function local_biterror end
function local_biterror(expr::Expression, x::AbstractArray)
    local_biterror(expr.tree, expr.metadata.operators, x)
end

"""
    function local_biterror(
        tree::Node{T},
        ops::AbstractOperatorEnum,
        X::AbstractMatrix{T};
        accum=default_accum
    ) where {T}

Compute the error per node/operation in `tree`. For each node, the children are
evaluated exactly, such that only the error of the current node is returned.
[`local_biterrors`](@ref) computes the error for all nodes in the tree.
"""
function local_biterror(
    tree::Node{T}, ops::AbstractOperatorEnum, X::AbstractMatrix{T}; accum=default_accum
) where {T}
    if tree.degree == 0 #|| tree.constant
        return T(0)
    end
    # each BigFloat from evaluate_exact might have different precision
    exact_args = [evaluate_exact(a, ops, X) for a in arguments(tree)]
    # @show exact_args
    prec = maximum_precision(exact_args)

    localf = tree.degree == 2 ? ops.binops[tree.op] : ops.unaops[tree.op]

    approx_args = convert_args(T, exact_args)
    approx_result = localf.(approx_args...)

    exact_args = [BigFloat.(x, prec) for x in exact_args]
    exact_result = evaluate_exact.(T, localf, exact_args...)
    bits = setprecision(prec) do
        map(zip(approx_result, exact_result)) do (ap, ex)
            biterror(ap, convert(T, ex))
        end
    end
    accum(bits)
end

"""
    local_biterrors(expr::Expression, x::AbstractArray)

Recursively call [`local_biterror`](@ref) on all nodes in `expr` and return the
local error for each node.
"""
function local_biterrors end
function local_biterrors(expr::Expression, x::AbstractArray)
    local_biterrors(expr.tree, expr.metadata.operators, x)
end
function local_biterrors(tree::Node{T}, ops::AbstractOperatorEnum, X::AbstractMatrix{T}) where {T}
    Dict(e => local_biterror(e, ops, X) for e in all_subexpressions(tree))
end
