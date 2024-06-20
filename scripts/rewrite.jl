using BenchmarkTools
using OptiFloat: local_biterror, sample_bitpattern, all_subexpressions, lambdify, rewrite_once
using TermInterface: iscall, operation
using DynamicExpressions

include("cas.jl")

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


expr = :((1/(x-1) - 2/x) + (1/(x+1)))
expr = :((1/(x-1) - 2/x) + (1/(x+1)) + cos(x))
expr = :(x+1)



function direct_left_to_right(r::RewriteRule{typeof(|>)})
    if length(r.name) > 0
        eval(:(@rule $(r.name) $(repr(r.left)) -->  $(repr(r.right))))
    else
        eval(:(@rule $(repr(r.left)) -->  $(repr(r.right))))
    end
end
function direct_right_to_left(r::RewriteRule{typeof(|>)})
    if length(r.name) > 0
        eval(:(@rule $(r.name) $(repr(r.right)) -->  $(repr(r.left))))
    else
        eval(:(@rule $(repr(r.right)) -->  $(repr(r.left))))
    end
end

direct(r::RewriteRule{typeof(|>)}) = (direct_left_to_right(r), direct_right_to_left(r))
direct(r::RewriteRule) = (r,)

function eqrules_to_dirrules(theory)
    newtheory = eltype(theory)[]
    for r in theory
        for s in straighten(r)
            push!(newtheory, s)
        end
    end
    newtheory
end
no_equality_rules_theory = eqrules_to_dirrules(CAS_THEORY)

rewrite_once(:(a+b), no_equality_rules_theory)


T = Float64
xs = sample_bitpattern(T, 100)

unary, binary = unary_binary_ops(expr)
operators = OperatorEnum(; binary_operators=binary, unary_operators=unary)
x1 = Node{T}(feature=1)
expression = lambdify(expr, :x)(x1)
X  = reshape(xs, 1, :)
expression(X, operators)


point = (;x=xs)

d = Dict(e => local_biterror(e,point) for e in all_subexpressions(expr))

@btime Dict(e => local_biterror(e,$point) for e in all_subexpressions($expr))
