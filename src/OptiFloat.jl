module OptiFloat

using DynamicExpressions: Node, OperatorEnum
using DynamicExpressions
using TermInterface
using IntervalArithmetic: Interval, interval, bounds, isthin, mid, isbounded
using Statistics: mean
using Metatheory: EGraph, SaturationParams, saturate!, extract!
using Metatheory.Rewriters: PassThrough, Postwalk

# FIXME: type piracy
Base.isfinite(x::Interval) = isbounded(x)

include("terminterface.jl")
include("sample.jl")
include("evaluate.jl")
include("error.jl")
include("rules.jl")

function rewrite_once(expr, theory)
    unique(vcat([expr], map(rule -> PassThrough(rule)(expr), theory)))
end
#rewrite_once(expr, theory) = vcat([expr], map(rule -> PassThrough(rule)(expr), theory))

function recursive_rewrite(expr::E, theory, depth=3) where E
    if iscall(expr) && depth > 0
        op = operation(expr)
        # rewrite all arguments to op
        argss = [recursive_rewrite(a, theory, depth - 1) for a in arguments(expr)]
        # all combinations of rewritten arguments
        argss = Iterators.product(argss...)
        # rewrite op itself
        rwo = if expr isa Expr  # FIXME: uglyyyy
            [rewrite_once(maketerm(E, :call, (op, args...), nothing), theory) for args in argss]
        else
            [rewrite_once(maketerm(E, op, collect(args), nothing), theory) for args in argss]
        end
        reduce(vcat, rwo)
    else
        [expr]
    end
end
recursive_rewrite(x::Union{Symbol,Number}, theory, depth=3) = [x]

replace_syms(s, syms::Dict) = haskey(syms, s) ? syms[s] : s
function replace_syms(expr::Expr, syms::Dict)
    cs = [replace_syms(e, syms) for e in children(expr)]
    maketerm(Expr, head(expr), cs, nothing)
end

toexpr(e::Node, symbol_map) = replace_syms(Meta.parse(repr(e)), symbol_map)

function simplify(expr, theory; steps=1, timeout=10)
    for _ in 1:steps
        g = EGraph(expr)
        p = SaturationParams(;
            timeout=timeout,
            scheduler=Schedulers.BackoffScheduler,
            schedulerparams=(match_limit=6000, ban_length=5),
            timer=false,
        )
        saturate!(g, theory, p)
        expr = extract!(g, astsize)
    end
    expr
end

struct Candidate{E<:Expression,A<:AbstractArray,F<:Function}
    cand_expr::E
    orig_expr::E
    used::Base.RefValue{Bool}
    errors::A
    toexpr::F
end
function Candidate(candidate, original, points::AbstractMatrix)
    errs = biterror(candidate, original, points; accum=identity)
    vars = candidate.metadata.variable_names
    ops = candidate.metadata.operators
    function toexpr(n::Node)::Expr
        Meta.parse(string_tree(n, ops; variable_names=vars))
    end
    Candidate(candidate, original, Ref(false), errs, toexpr)
end
function Base.show(io::IO, c::Candidate)
    u = c.used[] ? "✓" : "⊚"
    # converting to bigfloat because mean might overflow (e.g. for Float16)
    e = convert(eltype(c.errors), mean(convert(Vector{BigFloat}, c.errors)))
    print(io, "$u E=$(e) : $(string_tree(c.cand_expr))")
end

function first_unused(candidates)
    for c in candidates
        if !(c.used[])
            return c
        end
    end
    error("No more unused candidates!")
end

function optifloat!(candidates::Vector{<:Candidate}, points::Matrix{T}) where {T}
    candidate = first_unused(candidates)

    @info "Computing local error..."
    local_errs = local_biterrors(candidate.cand_expr, points)

    (err, worst_expr) = findmax(local_errs)
    @info "Expression with highest local error" worst_expr err

    @info "Recursive rewrite to obtain new candidate expressions"
    expr = candidate.toexpr(worst_expr)
    # FIXME: replace with postwalk?
    new_candidates = unique(recursive_rewrite(expr, OptiFloat.REWRITE_THEORY))

    @info "Simplifying candidates"
    all_improved = map(new_candidates) do newc
        simplified = simplify(newc, OptiFloat.SIMPLIFY_THEORY; steps=3)
    end |> unique

    @info "Reconstruct with simplified candidates"
    all_simplified =
        map(all_improved) do improved
            rewrite = Postwalk(PassThrough(x -> x == expr ? improved : nothing))
            e = rewrite(candidate.toexpr(candidate.cand_expr.tree))
            simplify(e, OptiFloat.SIMPLIFY_THEORY; steps=3)
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

    @info "TODO: regime inference"
end

end # module OptiFloat
