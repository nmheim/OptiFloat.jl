using Metatheory
using DynamicExpressions
using OptiFloat
using OptiFloat: all_subexpressions, evaluate_exact, accuracy,
    sample_bitpattern, ulpdistance, biterror, lambdify, biterrorscore, local_biterror, @dynexpr,
    evaluate_approx, recursive_rewrite

function simplify(expr, theory; steps=1)
    for _ in 1:steps
        g = EGraph(expr)
        p = SaturationParams(
            timeout = 10,
            scheduler = Schedulers.BackoffScheduler,
            schedulerparams = (match_limit = 6000, ban_length = 5),
            timer = false,
        )
        saturate!(g, theory)
        expr = extract!(g, astsize)
    end
    expr
end


T = Float16
orig_expr = :((-b - sqrt(b^2 - (4*a)*c)) / (2*c))
dexpr, ops, toexpr = eval(:(@dynexpr($T, $orig_expr)))
@info "defined expression" orig_expr

@info "computing local error"
X = sample_bitpattern(dexpr, ops, T, 3, 1000)
d = Dict(e => local_biterror(e,ops,X) for e in all_subexpressions(dexpr))

(error, worst_expr) = findmax(d)
@info "picked expression with highest local error" worst_expr error

@info "recursive rewrite to obtain new candidate expressions"
expr = toexpr(worst_expr)
candidates = recursive_rewrite(expr,OptiFloat.REWRITE_THEORY)[1:10]

@info "simplify rewritten"
all_improved = map(candidates) do cand
    simplify(cand, OptiFloat.SIMPLIFY_THEORY, steps=3)
end |> unique
theories = map(all_improved) do improved
    r = eval(:(@rule a b c $expr --> $(improved)))
    RewriteRule[r]
end
all_simplified = map(theories) do t
    e = rewrite(orig_expr, t)
    simplify(e, OptiFloat.SIMPLIFY_THEORY, steps=3)
end |> unique

results = map(all_simplified) do simpl
    new_dexpr, new_ops, _ = eval(:(@dynexpr $T $simpl))
    (new_dexpr, new_ops)
end

x = reshape(T[1,-1e2,1], 3, 1)
for (new_dexpr, new_ops) in results
    old = dexpr(x,ops)[1]
    new = new_dexpr(x,new_ops)[1]
    exact = evaluate_exact(dexpr,ops,x)[1]
    @info "Compare old/new" old new exact
end

@info "infer regimes... not done yet"
