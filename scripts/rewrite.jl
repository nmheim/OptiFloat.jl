using BenchmarkTools
using Metatheory
using Metatheory.Library
using Metatheory: direct
using OptiFloat: local_biterror, sample_bitpattern, all_subexpressions, lambdify, rewrite_once,
    recursive_rewrite, biterror
using TermInterface: iscall, operation

function eqrules_to_dirrules(theory)
    newtheory = eltype(theory)[]
    for r in theory
        for s in direct(r)
            push!(newtheory, s)
        end
    end
    newtheory
end

function simplify(expr, theory; steps=1)
    for _ in 1:steps
        g = EGraph(expr)
        saturate!(g, theory)
        expr = extract!(g, astsize)
    end
    expr
end


REWRITE_THEORY = @theory a x y z begin
    -x == 0 - x
    x+y --> (x^2-y^2) / (x-y)
    (x-y)+z == x-(y-z) 
end

expr = :((-b + sqrt(b^2 - 4*a*c)) / (2*a))
rws = recursive_rewrite(expr, eqrules_to_dirrules(REWRITE_THEORY))

SIMPLIFY_THEORY = @theory a x y z begin
    -x == 0 - x
    x+y --> (x^2-y^2) / (x-y)
    (x-y)+z == x-(y-z) 

    sqrt(x)^2 --> x
    (-x)^2 --> x^2

    x - x --> 0
    0 + x --> x

    x / y / z --> x / (y * z)
    (a*x) / (a*y) --> x/y
end
SIMPLIFY_THEORY = SIMPLIFY_THEORY ∪ @commutative_monoid (*) 1


improved = map(rws) do rw
    simplify(rw, SIMPLIFY_THEORY, steps=3)
end |> unique


T = Float16
batchsize=100
batch = (;
    a=rand(T,batchsize),
    b=rand(T,batchsize),
    c=rand(T,batchsize),
)

d = Dict(e => local_biterror(e,batch) for e in all_subexpressions(expr))

@btime Dict(e => local_biterror(e,$point) for e in all_subexpressions($expr))
