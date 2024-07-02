using Metatheory
using DynamicExpressions
using OptiFloat
using OptiFloat: all_subexpressions, evaluate_exact, accuracy,
    sample_bitpattern, ulpdistance, biterror, lambdify, biterrorscore, local_biterror, @dynexpr,
    evaluate_approx, recursive_rewrite, simplify, Candidate


function first_unused(candidates)
    for c in candidates
        if !(c.used[])
            return c
        end
    end
    error("No more unused candidates!")
end

function make_candidate(expr::Expr, points)
    dexpr, ops, toexpr = eval(:(@dynexpr($T, $(expr))))
    make_candidate(expr, points, dexpr, ops, toexpr)
end
function make_candidate(expr::Expr, points, dexpr, ops, toexpr)
    @info "make candi" expr
    (;
     expr=expr,
     dexpr=dexpr,
     ops=ops,
     used=Ref(false),
     errors=biterror(dexpr,ops,points,accum=identity),
     toexpr=toexpr,
    )
end

T = Float16
orig_expr = :((-b - sqrt(b^2 - (4*a)*c)) / (2*c))
dexpr, ops, toexpr = eval(:(@dynexpr($T, $(orig_expr))))
points = sample_bitpattern(dexpr, ops, T, 3, 8000)
candidates = Any[ Candidate(orig_expr, points) ]


#function optifloat!(candidates, points::Matrix{T}) where T
    candidate = first_unused(candidates)
    
    @info "Computing local error..."
    local_errs = Dict(e => local_biterror(e,ops,points) for e in all_subexpressions(dexpr))
    
    (err, worst_expr) = findmax(local_errs)
    @info "Expression with highest local error" worst_expr err
    
    @info "Recursive rewrite to obtain new candidate expressions"
    expr = candidate.toexpr(worst_expr)
    new_candidates = recursive_rewrite(expr,OptiFloat.REWRITE_THEORY)[1:10]
    
    @info "Simplifying candidates"
    all_improved = map(new_candidates) do newc
        simplified = simplify(newc, OptiFloat.SIMPLIFY_THEORY, steps=3)
    end |> unique
    theories = map(all_improved) do improved
        r = eval(:(@rule a b c $expr --> $(improved)))
        RewriteRule[r]
    end
    
    @info "Reconstruct with simplified candidates"
    all_simplified = map(theories) do t
        e = rewrite(candidate.expr, t)
        simplify(e, OptiFloat.SIMPLIFY_THEORY, steps=3)
    end |> unique
    
    results = map(all_simplified) do simpl
        new_dexpr, new_ops, _ = eval(:(@dynexpr $T $simpl))
        (new_dexpr, new_ops)
    end

    new_cs = Any[]
    for simpl in all_simplified
        new_candiate = Candidate(simpl, points)
        if any([any(new_candiate.errors .< c.errors) for c in candidates])
            push!(new_cs, new_candiate)
        end
    end

    candidates = vcat(candidates, new_cs)
    candidate.used[] = true
#end


# optifloat!(candidates, points)
