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

rewrite_once(x, theory) = [x]
function rewrite_once(expr::Expr, theory)
    # FIXME: replace with looped PassThrough
    rws = [expr]
    for rule in theory
        rw = try
            rule(expr)
        catch e
            e isa BoundsError ? nothing : rethrow(e)
        end
        if !isnothing(rw)
            push!(rws, rw)
        end
    end
    rws
end

recursive_rewrite(x, theory, depth=3) = [x]
function recursive_rewrite(expr::Expr, theory, depth=3)
    #  FIXME: replace with Postwalk
    if iscall(expr) && depth > 0
        op = operation(expr)
        argss =
            Iterators.product(
                [recursive_rewrite(a, theory, depth - 1) for a in arguments(expr)]...
            ) |>
            collect |>
            vec
        rwo = [rewrite_once(Expr(:call, op, args...), theory) for args in argss]
        rws = reduce(vcat, rwo)
        rws
    else
        [expr]
    end
end

#_symbols(e::Expr) = filter(x -> x isa Symbol, all_subexpressions(e))
#
#function DynamicExpressions.parse_expression(ex, node_type)
#    vars = sort(string.(_symbols(ex)))
#    (unaops, binops) = unary_binary_ops(ex)
#    parse_expression(
#        ex,
#        variable_names=vars,
#        binary_operators=binops,
#        unary_operators=unaops,
#        node_type=node_type
#    )
#end
#
#function unary_binary_ops(expr)
#    ops = eval.(unique(operation.(filter(iscall, all_subexpressions(expr)))))
#    unary = Function[]
#    binary = Function[]
#    for op in ops
#        nargs = maximum([m.nargs-1 for m in methods(op)])
#        if nargs > 1
#            push!(binary, op)
#            # special case for e.g.: -1 or -x
#            if op == -
#                push!(unary, op)
#            end
#        else
#            push!(unary, op)
#        end
#    end
#    (unary, binary)
#end

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
