module OptiFloat

using DynamicExpressions: Node, OperatorEnum
using TermInterface
using IntervalArithmetic: Interval, interval, bounds, isthin, mid, isbounded
using Statistics: mean


const Point{syms,N,T} = NamedTuple{syms, <:NTuple{N,T}} where {syms,N,T<:Real}
const Batch{syms,N,T} = NamedTuple{syms, <:NTuple{N,Vector{T}}} where {syms,N,T<:Real}

include("sample.jl")
include("evaluate.jl")
include("oracle.jl")

rewrite_once(x, theory) = [x]
function rewrite_once(expr::Expr, theory)
    rws = [expr]
    for rule in theory
        rw = try
            rule(expr)
        catch e
            e isa BoundsError ? nothing : rethrow(e)
        end
        if !isnothing(rw)
            push!(rws, rw)
        end
    end
    rws
end

recursive_rewrite(x, theory) = [x]
function recursive_rewrite(expr::Expr, theory)
    if iscall(expr)
        op = operation(expr)
        argss = Iterators.product([recursive_rewrite(a, theory) for a in arguments(expr)]...) |> collect |> vec
        rwo = [rewrite_once(Expr(:call, op, args...), theory) for args in argss]
        rws = reduce(vcat, rwo)
        rws
    else
        [expr]
    end
end

_symbols(e::Expr) = filter(x -> x isa Symbol, all_subexpressions(e))

function unary_binary_ops(expr)
    ops = eval.(unique(operation.(filter(iscall, all_subexpressions(expr)))))
    unary = []
    binary = []
    for op in ops
        nargs = maximum([m.nargs-1 for m in methods(op)])
        if nargs > 1
            push!(binary, op)
        else
            push!(unary, op)
        end
    end
    (unary, binary)
end

function _dynexpr(T::Type{<:Number}, expr::Expr)
    syms = _symbols(expr)
    nodes = [:($s = Node{$T}(feature=$i)) for (i,s) in enumerate(syms)]
    unary, binary = unary_binary_ops(expr)
    quote
        $(nodes...)
        operators = OperatorEnum(; binary_operators=$binary, unary_operators=$unary)
        $expr, operators, $syms
    end
end

macro dynexpr(T, expr)
    :($(_dynexpr(eval(T), expr)))
end


end # module OptiFloat
