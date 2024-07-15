module OptiFloat

using DynamicExpressions: Node, AbstractOperatorEnum
using DynamicExpressions
using TermInterface
using IntervalArithmetic: Interval, interval, bounds, isthin, mid, isbounded
using Statistics: mean
using Metatheory: EGraph, SaturationParams, saturate!, extract!
using Metatheory.Rewriters: PassThrough, Postwalk

# FIXME: type piracy
Base.isfinite(x::Interval) = isbounded(x)

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



include("rules-minus.jl")
include("rewrite.jl")
include("terminterface.jl")
include("sample.jl")
include("evaluate.jl")
include("error.jl")
include("infer-regimes.jl")

replace_syms(s, syms::Dict) = haskey(syms, s) ? syms[s] : s
function replace_syms(expr::Expr, syms::Dict)
    cs = [replace_syms(e, syms) for e in children(expr)]
    maketerm(Expr, head(expr), cs, nothing)
end

toexpr(e::Node, symbol_map) = replace_syms(Meta.parse(repr(e)), symbol_map)

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
    @info "errors:" local_errs

    (err, worst_expr) = findmax(local_errs)
    @info "Expression with highest local error" worst_expr err

    @info "Recursive rewrite to obtain new candidate expressions"
    expr = candidate.toexpr(worst_expr)
    alts = recursive_rewrite(expr; depth=2)

    @info "Reconstruct with simplified candidates"
    reconstructed = map(alts) do alt
        reconstruct = Postwalk(PassThrough(x -> x == expr ? alt : nothing))
        reconstruct(candidate.toexpr(candidate.cand_expr.tree))
    end
    display(reconstructed)

    # TODO: Jaques Carrett knows about unsound rules e.g. to deal with
    #  :(((4.0c) / (b + sqrt(b ^ 2.0 - 4.0c))) / (2.0c)) division by zero

    new_cs = Any[]
    for alt in reconstructed
        metadata = candidate.cand_expr.metadata
        new_dexpr = parse_expression(alt;
            binary_operators=metadata.operators.binops |> collect,
            unary_operators=metadata.operators.unaops |> collect,
            variable_names=metadata.variable_names,
            node_type=Node{T},
        )
        new_candidate = Candidate(new_dexpr, candidate.orig_expr, points)
        @info new_candidate
        if any([any(new_candidate.errors .< c.errors) for c in candidates])
            push!(new_cs, new_candidate)
        end
    end

    append!(candidates, new_cs)
    unique!(candidates)
    candidate.used[] = true
    sort!(candidates, by=c->mean(convert(Vector{BigFloat}, c.errors)))
    display(candidates)

    @info "TODO: regime inference"
end

end # module OptiFloat
