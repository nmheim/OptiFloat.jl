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
    local_biterrors, first_unused

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

    (err, worst_expr) = findmax(local_errs)
    @info "Expression with highest local error" worst_expr err

    @info "Recursive rewrite to obtain new candidate expressions"
    # expr = candidate.toexpr(worst_expr)
    new_candidates = recursive_rewrite(dexpr, OptiFloat.REWRITE_THEORY; depth=2)

    Metatheory.EGraphs._get_metadata(::Type{<:Expression}) =
        DynamicExpressions.ExpressionModule.Metadata((;
            operators=DynamicExpressions.OperatorEnumConstructionModule.LATEST_OPERATORS[],
            variable_names=DynamicExpressions.OperatorEnumConstructionModule.LATEST_VARIABLE_NAMES[],
        ))
        
    @info "Simplifying candidates"
    all_improved = map(new_candidates) do newc
        simplified = simplify(newc, OptiFloat.SIMPLIFY_THEORY; steps=1)
    end |> unique

    $ TODO: only rewrite CHILDREN OF MOST RECENTLY REWRITTEN OPERATION!!!
    @info "Reconstruct with simplified candidates"
    all_simplified =
        map(all_improved) do improved
            rewrite = Postwalk(PassThrough(x -> x == dexpr ? improved : nothing))
            e = rewrite(candidate.toexpr(candidate.cand_expr.tree))
            simplify(e, OptiFloat.SIMPLIFY_THEORY; steps=1)
        end |> unique

    # TODO: Jaques Carrett knows about unsound rules e.g. to deal with
    #  :(((4.0c) / (b + sqrt(b ^ 2.0 - 4.0c))) / (2.0c)) division by zero

    new_cs = Any[]
    for simpl in all_simplified
        expr = candidate.cand_expr
        new_dexpr = parse_expression(
            simpl;
            binary_operators=expr.metadata.operators.binops |> collect,
            unary_operators=expr.metadata.operators.unaops |> collect,
            variable_names=expr.metadata.variable_names,
            node_type=Node{T},
        )
        new_candidate = Candidate(new_dexpr, candidate.orig_expr, points)
        if any([any(new_candidate.errors .< c.errors) for c in candidates])
            push!(new_cs, new_candidate)
        end
    end

    append!(candidates, new_cs)
    unique!(candidates)
    candidate.used[] = true
    display(candidates)


