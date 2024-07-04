using Metatheory
using DynamicExpressions
using OptiFloat
using OptiFloat:
    all_subexpressions,
    evaluate_exact,
    sample_bitpattern,
    ulpdistance,
    biterror,
    biterrorscore,
    logsample,
    evaluate_approx,
    recursive_rewrite,
    simplify,
    Candidate,
    local_biterrors

function first_unused(candidates)
    for c in candidates
        if !(c.used[])
            return c
        end
    end
    error("No more unused candidates!")
end

T = Float16
orig_expr = :(sqrt(x + 1) - sqrt(x))
kws = (;
    binary_operators=[-, ^, /, *, +],
    unary_operators=[-, sqrt],
    node_type=Node{T},
    variable_names=["x"],
)
dexpr = parse_expression(orig_expr; kws...)
arity = length(dexpr.metadata.variable_names)
points = sample_bitpattern(dexpr, T, arity, 8000)
points = logsample(dexpr, T, arity, 8000)
candidates = [Candidate(dexpr, points)]

#function optifloat!(candidates, points::Matrix{T}) where T
candidate = first_unused(candidates)

@info "Computing local error..."
local_errs = local_biterrors(dexpr, points)

(err, worst_expr) = findmax(local_errs)
@info "Expression with highest local error" worst_expr err

@info "Recursive rewrite to obtain new candidate expressions"
expr = candidate.toexpr(worst_expr)
new_candidates = unique(recursive_rewrite(expr, OptiFloat.REWRITE_THEORY))#[1:10]

@info "Simplifying candidates"
all_improved = map(new_candidates) do newc
    simplified = simplify(newc, OptiFloat.SIMPLIFY_THEORY; steps=3)
end |> unique
theories = map(all_improved) do improved
    r = eval(:(@rule a b c $expr --> $(improved)))
    RewriteRule[r]
end

@info "Reconstruct with simplified candidates"
all_simplified = map(theories) do t
    e = rewrite(candidate.toexpr(candidate.expr.tree), t)
    simplify(e, OptiFloat.SIMPLIFY_THEORY; steps=3)
end |> unique

new_cs = Any[]
for simpl in all_simplified
    new_dexpr = parse_expression(simpl; kws...)
    new_candiate = Candidate(new_dexpr, points)
    if any([any(new_candiate.errors .< c.errors) for c in candidates])
        push!(new_cs, new_candiate)
    end
end

candidates = vcat(candidates, new_cs) |> unique
candidate.used[] = true
display(candidates)

@info "TODO: regime inference"
#end

# optifloat!(candidates, points)
