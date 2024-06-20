using BenchmarkTools
using OptiFloat: local_biterror, sample_bitpattern, all_subexpressions, lambdify, rewrite_once, recursive_rewrite
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


_direct(name, left, right) = eval(:(@rule $name $(Meta.parse(repr(left))) --> $(Meta.parse(repr(right)))))

direct_left_to_right(r::RewriteRule{typeof(==)}) = _direct(r.name, r.left, r.right)
direct_right_to_left(r::RewriteRule{typeof(==)}) = _direct(r.name, r.right, r.left)

direct(r::RewriteRule{typeof(==)}) = (direct_left_to_right(r), direct_right_to_left(r))
direct(r::RewriteRule) = (r,)

function eqrules_to_dirrules(theory)
    newtheory = eltype(theory)[]
    for r in theory
        for s in direct(r)
            push!(newtheory, s)
        end
    end
    newtheory
end



r = @rule "distributive" a b c a * (b+c) == (a+b) * (a+c)
no_equality_rules_theory = eqrules_to_dirrules(CAS_THEORY)

rewrite_once(:(a*(c+(0*a))), no_equality_rules_theory)
recursive_rewrite(:(a+b), no_equality_rules_theory)
recursive_rewrite(:(a*(c+b)), no_equality_rules_theory)
recursive_rewrite(:(a*(c+(0*a + a*1))), no_equality_rules_theory)

TEST_THEORY = @theory a x y z begin
    -x --> 0 - x
    x+y --> (x^2-y^2) / (x-y)
    (x-y)+z == x-(y-z) 

    sqrt(x)^2 --> x
    (-x)^2 --> x^2

    x - x --> 0
    0 + x --> x

    x / y / z --> x / (y * z)
    (a*x) / (a*y) --> x/y
end
TEST_THEORY = TEST_THEORY ∪ @commutative_monoid (*) 1

expr = :((-b + sqrt(b^2 - 4*a*c)) / (2*a))
#expr = :(-a *(b+c))
rws = recursive_rewrite(expr, eqrules_to_dirrules(TEST_THEORY))

g = EGraph(rws[2])
#g = EGraph(:(4a / b / 2a))
saturate!(g, TEST_THEORY)
extract!(g, astsize)


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
