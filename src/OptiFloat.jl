module OptiFloat

using DynamicExpressions: Node, OperatorEnum
using TermInterface
using IntervalArithmetic: Interval, interval, bounds, isthin, mid, isbounded
using Statistics: mean


const Point{syms,N,T} = NamedTuple{syms, <:NTuple{N,T}} where {syms,N,T<:Real}
const Batch{syms,N,T} = NamedTuple{syms, <:NTuple{N,Vector{T}}} where {syms,N,T<:Real}

include("sample.jl")
include("evaluate.jl")
include("error.jl")
include("rules.jl")

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

recursive_rewrite(x, theory, depth=3) = [x]
function recursive_rewrite(expr::Expr, theory, depth=3)
    if iscall(expr) && depth>0
        op = operation(expr)
        argss = Iterators.product([recursive_rewrite(a, theory, depth-1) for a in arguments(expr)]...) |> collect |> vec
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
            # special case for e.g.: -1 or -x
            if op == -
                push!(unary, op)
            end
        else
            push!(unary, op)
        end
    end
    (unary, binary)
end

replace_syms(s, syms::Dict) = haskey(syms,s) ? syms[s] : s
function replace_syms(expr::Expr, syms::Dict)
    cs = [replace_syms(e, syms) for e in children(expr)]
    maketerm(Expr, head(expr), cs, nothing)
end

toexpr(e::Node, symbol_map) = replace_syms(Meta.parse(repr(e)), symbol_map)

function dynexpr(T::Type{<:Number}, expr::Expr)
    syms = sort(_symbols(expr))
    nodes = [:($s = Node{$T}(feature=$i)) for (i,s) in enumerate(syms)]
    node_to_syms = Dict(Symbol(string(Node{T}(feature=i)))=>s for (i,s) in enumerate(syms))
    unary, binary = unary_binary_ops(expr)
    quote
        let $(nodes...), operators=OperatorEnum(; binary_operators=$binary, unary_operators=$unary)
            ($expr, operators, e->toexpr(e, $node_to_syms))
        end
    end
end

macro dynexpr(T, expr)
    :($(dynexpr(eval(T), expr)))
end

function simplify(expr, theory; steps=1, timeout=10)
    for _ in 1:steps
        g = EGraph(expr)
        p = SaturationParams(
            timeout = timeout,
            scheduler = Schedulers.BackoffScheduler,
            schedulerparams = (match_limit = 6000, ban_length = 5),
            timer = false,
        )
        saturate!(g, theory)
        expr = extract!(g, astsize)
    end
    expr
end


struct Candidate{D,O,A,F}
     expr::Expr
     dexpr::D
     ops::O
     used::Base.RefValue{Bool}
     errors::A
     toexpr::F
end
function Candidate(expr, dexpr, ops, toexpr, points::AbstractMatrix)
    errs = biterror(dexpr,ops,points,accum=identity)
    Candidate(expr, dexpr, ops, Ref(false), errs, toexpr)
end
function Candidate(expr, points::AbstractMatrix{T}) where T
    dexpr, ops, toexpr = eval(:(@dynexpr($T, $(expr))))
    Candidate(expr, dexpr, ops, toexpr, points)
end

function Base.show(io::IO, c::Candidate)
    u = c.used[] ? "✓" : "×"
    print(io, "$u E=$(mean(c.errors)) : $(c.expr)")
end

end # module OptiFloat
