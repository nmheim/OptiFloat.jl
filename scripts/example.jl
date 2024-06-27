using Metatheory
using DynamicExpressions
using OptiFloat
using OptiFloat: all_subexpressions, evaluate_exact, accuracy,
    sample_bitpattern, ulpdistance, biterror, lambdify, biterrorscore, local_biterror, @dynexpr,
    evaluate_approx, recursive_rewrite

function simplify(expr, theory; steps=1)
    for _ in 1:steps
        g = EGraph(expr)
        saturate!(g, theory)
        expr = extract!(g, astsize)
    end
    expr
end

toexpr(e::Node) = Meta.parse(repr(e))

replace_syms(s, syms::Dict) = haskey(syms,s) ? syms[s] : s
function replace_syms(expr::Expr, syms::Dict)
    cs = [replace_syms(e, syms) for e in children(expr)]
    maketerm(Expr, head(expr), cs, nothing)
end


@info "define expression"
T = Float16
orig_expr = :((-1x2 - sqrt(x2^2 - 4*x1*x3)) / (2*x3))
dexpr, ops, syms = eval(:(@dynexpr $T $orig_expr))

@info "compute local error"
X = sample_bitpattern(dexpr, ops, T, 3, 1000)
d = Dict(e => local_biterror(e,ops,X) for e in all_subexpressions(dexpr))

@info "pick expression with highest local error"
(_, worst_expr) = findmax(d)

@info "recursive rewrite to obtain new candidate expressions"
expr = toexpr(worst_expr)
candidates = recursive_rewrite(expr,OptiFloat.REWRITE_THEORY)

@info "simplify rewritten"
improved = map(candidates) do cand
    simplify(cand, OptiFloat.SIMPLIFY_THEORY, steps=3)
end |> unique
improved = improved[3]

r = eval(:(@rule x1 x2 x3 $expr --> $(improved)))
new = simplify(orig_expr, vcat(OptiFloat.SIMPLIFY_THEORY,[r]))
new = simplify(orig_expr, RewriteRule[r])
new = replace_syms(new, Dict(:x1=>:a, :x2=>:b, :x3=>:c))
@info "Reconstruct with simplified candidates" new

new_dexpr, new_ops, syms = eval(:(@dynexpr $T $new))
x = reshape(T[1,-1e2,1], 3, 1)
@info "compare old/new" dexpr(x,ops)[1] new_dexpr(x,new_ops)[1] evaluate_exact(dexpr,ops,x)[1]


@info "infer regimes... not done yet"
