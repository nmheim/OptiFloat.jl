using Metatheory
using OptiFloat: all_subexpressions, evaluate_exact, accuracy,
    sample_bitpattern, ulpdistance, biterror, lambdify, biterrorscore, local_biterror, @dynexpr, evaluate_approx, recursive_rewrite

# define expression
T = Float16
expr = :((-1b - sqrt(b^2 - 4*a*c)) / (2*a))
dexpr, ops, syms = eval(:(@dynexpr $T $expr))

# compute local error
X = sample_bitpattern(dexpr, ops, T, 3, 1000)
d = Dict(e => local_biterror(e,ops,X) for e in all_subexpressions(dexpr))

# pick expression with highest local error
(_, worst_expr) = findmax(d)

# rewrite & simplify
include("example_rules.jl")
using DynamicExpressions
toexpr(e::Node) = Meta.parse(repr(e))
expr = toexpr(worst_expr)
expr = :(-b - sqrt(b^2 - 4*a*c))
rws = recursive_rewrite(expr,REWRITE_THEORY)
improved = map(rws) do rw
    simplify(rw, SIMPLIFY_THEORY, steps=3)
end |> unique
improved = improved[2]

orig_expr = :((-(b) - sqrt(b^2 - 4*a*c)) / (2*a))
r = eval(:(@rule a b c $expr --> $(improved)))
new = recursive_rewrite(orig_expr, [r])[2:end] |> only
new = simplify(new, SIMPLIFY_THEORY)
new = recursive_rewrite(new, [@rule x -x --> -1x])[2:end] |> only

new_dexpr, new_ops, syms = eval(:(@dynexpr $T $new))
x = reshape(T[1,-1e2,1], 3, 1)

@info "new" new_dexpr(x,new_ops)[1] dexpr(x,ops)[1] evaluate_exact(dexpr,ops,x)[1]
