using DynamicExpressions
using Metatheory
using Metatheory.Rewriters
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
    local_biterrors, first_unused, alternatives, AlternativeRewriter


T = Float16
orig_expr = :(sqrt(x + 1) - sqrt(x))
kws = (;
    binary_operators=[-, ^, /, *, +],
    unary_operators=[-, sqrt, abs, exp, log, cbrt],
    node_type=Node{T},
    variable_names=["x"],
)
dexpr = parse_expression(orig_expr; kws...)
# points = sample_bitpattern(dexpr, T, arity(dexpr), 8000)
points = logsample(dexpr, T, arity(dexpr), 8000)
candidates = [Candidate(dexpr, dexpr, points)]

    candidate = first_unused(candidates)

    @info "Computing local error..."
    local_errs = local_biterrors(candidate.cand_expr, points)

    (errr, worst_expr) = findmax(local_errs)
    @info "Expression with highest local error" worst_expr errr

    @info "Recursive rewrite to obtain new candidate expressions"
    expr = candidate.toexpr(worst_expr)
    #alt_exprs = map(r -> Postwalk(AlternativeRewriter(r))(expr), OptiFloat.REWRITE_THEORY)
    # FIXME: this should be Postwalk.... but running into Postwalk(@rule a a -> 1a)(orig_expr)
    alt_exprs = map(r -> AlternativeRewriter(r)(expr), OptiFloat.REWRITE_THEORY) |> unique
    alts = mapreduce(e->alternatives(e,OptiFloat.SIMPLIFY_THEORY), vcat, alt_exprs) |> unique

    # TODO: Jaques Carrett knows about unsound rules e.g. to deal with
    #  :(((4.0c) / (b + sqrt(b ^ 2.0 - 4.0c))) / (2.0c)) division by zero

    new_cs = Any[]
    for alt in alts
        new_dexpr = parse_expression(alt; kws...)
        new_candidate = Candidate(new_dexpr, candidate.orig_expr, points)
        if any([any(new_candidate.errors .< c.errors) for c in candidates])
            push!(new_cs, new_candidate)
        end
    end

    append!(candidates, new_cs)
    unique!(candidates)
    candidate.used[] = true
    display(candidates)


