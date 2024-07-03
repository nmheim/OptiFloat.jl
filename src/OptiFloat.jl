module OptiFloat

using DynamicExpressions: Node, OperatorEnum
using DynamicExpressions
using TermInterface
using IntervalArithmetic: Interval, interval, bounds, isthin, mid, isbounded
using Statistics: mean


# FIXME: type piracy
Base.isfinite(x::Interval) = isbounded(x)

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

#_symbols(e::Expr) = filter(x -> x isa Symbol, all_subexpressions(e))
#
#function DynamicExpressions.parse_expression(ex, node_type)
#    vars = sort(string.(_symbols(ex)))
#    (unaops, binops) = unary_binary_ops(ex)
#    parse_expression(
#        ex,
#        variable_names=vars,
#        binary_operators=binops,
#        unary_operators=unaops,
#        node_type=node_type
#    )
#end
#
#function unary_binary_ops(expr)
#    ops = eval.(unique(operation.(filter(iscall, all_subexpressions(expr)))))
#    unary = Function[]
#    binary = Function[]
#    for op in ops
#        nargs = maximum([m.nargs-1 for m in methods(op)])
#        if nargs > 1
#            push!(binary, op)
#            # special case for e.g.: -1 or -x
#            if op == -
#                push!(unary, op)
#            end
#        else
#            push!(unary, op)
#        end
#    end
#    (unary, binary)
#end

replace_syms(s, syms::Dict) = haskey(syms,s) ? syms[s] : s
function replace_syms(expr::Expr, syms::Dict)
    cs = [replace_syms(e, syms) for e in children(expr)]
    maketerm(Expr, head(expr), cs, nothing)
end

toexpr(e::Node, symbol_map) = replace_syms(Meta.parse(repr(e)), symbol_map)

function simplify(expr, theory; steps=1, timeout=10)
    for _ in 1:steps
        g = EGraph(expr)
        p = SaturationParams(
            timeout = timeout,
            scheduler = Schedulers.BackoffScheduler,
            schedulerparams = (match_limit = 6000, ban_length = 5),
            timer = false,
        )
        saturate!(g, theory, p)
        expr = extract!(g, astsize)
    end
    expr
end


struct Candidate{E<:Expression,A<:AbstractArray,F<:Function}
     expr::E
     used::Base.RefValue{Bool}
     errors::A
     toexpr::F
end
function Candidate(expr, points::AbstractMatrix)
    errs = biterror(expr,points,accum=identity)
    function toexpr(n::Node)::Expr
        Meta.parse(string_tree(n, expr.metadata.operators, variable_names=expr.metadata.variable_names))
    end
    Candidate(expr, Ref(false), errs, toexpr)
end
function Base.show(io::IO, c::Candidate)
    u = c.used[] ? "✓" : "⊚"
    print(io, "$u E=$(mean(c.errors)) : $(string_tree(c.expr))")
end

end # module OptiFloat
