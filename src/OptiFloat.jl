module OptiFloat

using DynamicExpressions: Node, AbstractOperatorEnum
using DynamicExpressions
using TermInterface
using IntervalArithmetic
using Statistics: mean, median
using Metatheory: EGraph, SaturationParams, saturate!, extract!
using Metatheory.Rewriters: PassThrough, Postwalk

using Term.Tables: Table
using Term: Panel, highlight_syntax
using Term.Renderables: info

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
    # converting to bigfloat because accum might overflow (e.g. for Float16)
    e = convert(eltype(c.errors), default_accum(convert(Vector{BigFloat}, c.errors)))
    print(io, "$u E=$(e) : $(string_tree(c.cand_expr))")
end
DynamicExpressions.string_tree(r::Candidate) = string_tree(r.cand_expr)

biterror(c::Candidate; accum=default_accum) = accum(c.errors)

struct Regime{T<:AbstractFloat,C,V<:AbstractVector}
    cand::C
    low::T
    high::T
    feature::Int
    error_mask::V
end
DynamicExpressions.string_tree(r::Regime) = string_tree(r.cand)
function Base.join(a::Regime, b::Regime)
    (a.feature == b.feature) && (b.low <= a.high <= b.high) || error("cannot join disjoint regimes")
    if a.cand.cand_expr == b.cand.cand_expr
        mask = convert(Vector{Bool}, min.(1, a.error_mask .+ b.error_mask))
        r = Regime(a.cand, a.low, b.high, a.feature, mask)
        PiecewiseRegime([r])
    else
        PiecewiseRegime([a, b])
    end
end
function Base.show(io::IO, r::Regime)
    e = biterror(r)
    v = r.cand.cand_expr.metadata.variable_names[r.feature]
    # FIXME: turn this into table
    println(io, "(E=$e, $(r.low) < $(v) <= $(r.high)) : $(string_tree(r))")
end
function Base.:(==)(a::Regime, b::Regime)
    a.cand == b.cand && a.low == b.low && a.high == b.high && a.feature == b.feature
end

function biterror(r::Regime; accum=default_accum)
    errs = biterror(r.cand; accum=identity)
    errs = errs[r.error_mask]
    accum(errs)
end

struct PiecewiseRegime{A<:AbstractVector{<:Regime}}
    regs::A
end
function PiecewiseRegime(rs::Tuple...)
    regs = [Regime(args...) for args in rs]
    @assert all(sum([r.error_mask for r in regs]) .== 1)
    PiecewiseRegime(regs)
end
function Base.join(a::PiecewiseRegime, r::Regime)
    PiecewiseRegime(vcat(a.regs[1:(end - 1)], join(a.regs[end], r).regs))
end

function print_report(original::Candidate, rs::PiecewiseRegime)
    result_panel = Table(
        OrderedDict(
            :Intervals => [(r.low, r.high) for r in rs.regs],
            :Error => [biterror(r) for r in rs.regs],
            :Expression => [string_tree(r.cand.cand_expr) for r in rs.regs],
        );
        columns_justify=[:left, :left, :left],
        footer=["Combined", "$(biterror(rs))", "%"],
        footer_justify=[:center, :left, :center],
        box=:ROUNDED,
    );

    orig_panel = Table(
        OrderedDict(
            :Interval => [(-Inf, Inf)],
            :Error => [biterror(original)],
            :Expression => [string_tree(original.orig_expr)],
        );
        columns_justify=[:left, :left, :left],
        box=:ROUNDED,
    )

    expr = regimes_to_expr(rs)
    func = Expr(:function, Expr(:call, :f, expr.args[1]...), expr.args[2])
    expression_panel = Panel(
        highlight_syntax("$(func)"),
        fit=true,
    )

    panel = Panel(
        "  Original Expression:",
        orig_panel,
        "  Optimized PiecewiseRegime:",
        result_panel,
        "  Final Expression:",
        expression_panel;
        fit=true,
        title="OptiFloat Result",
        title_justify=:center,
        justify=:center,
    )
    println("")
    print(string(panel))
end
function Base.:(==)(a::PiecewiseRegime, b::PiecewiseRegime)
    length(a.regs) == length(b.regs) && all(ra == rb for (ra, rb) in zip(a.regs, b.regs))
end

function biterror(rs::PiecewiseRegime; accum=default_accum)
    accum(mapreduce(r -> biterror(r; accum=identity), vcat, rs.regs))
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

    reconstructed = map(alts) do alt
        reconstruct = Postwalk(PassThrough(x -> x == expr ? alt : nothing))
        reconstruct(candidate.toexpr(candidate.cand_expr.tree))
    end

    @info "Computing error of new candidates..."
    for (i,alt) in enumerate(reconstructed)
        metadata = candidate.cand_expr.metadata
        new_dexpr = parse_expression(
            alt;
            binary_operators=metadata.operators.binops |> collect,
            unary_operators=metadata.operators.unaops |> collect,
            variable_names=metadata.variable_names,
            node_type=Node{T},
        )
        new_candidate = Candidate(new_dexpr, candidate.orig_expr, points)
        if any([any(new_candidate.errors .< c.errors) for c in candidates])
            push!(candidates, new_candidate)
        end

        # progress printing...
        print("\e[2K") # clear whole line
        print("\e[1G") # move cursor to column 1
        print(" ($i/$(length(reconstructed)))  ")
        _str = repr(new_candidate)
        length(_str)>50 ? print("$(_str[1:50])...") : print(_str)
    end
    println("")

    unique!(candidates)
    candidate.used[] = true
    sort!(candidates; by=c -> default_accum(convert(Vector{BigFloat}, c.errors)))

    return nothing
end

end # module OptiFloat
