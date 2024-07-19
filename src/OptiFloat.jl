module OptiFloat

using DynamicExpressions: Node, AbstractOperatorEnum
using DynamicExpressions
using TermInterface
using IntervalArithmetic
using Statistics: mean, median
using Metatheory: EGraph, SaturationParams, saturate!, extract!
using Metatheory.Rewriters: PassThrough, Postwalk
using Term: Table, Panel, highlight_syntax, remove_ansi
using Printf: @sprintf

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
Candidate(candidate, points) = Candidate(candidate, candidate, points)

toexpr(c::Candidate) = integerify(c.toexpr(c.cand_expr.tree))
integerify(e::Expr) = maketerm(Expr, head(e), integerify.(children(e)), nothing)
function integerify(x::AbstractFloat)
    try
        convert(Int, x)
    catch
        x
    end
end
integerify(x) = x

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

function format_interval(a, b)
    x = Float64(a)
    y = Float64(b)
    l = x == -Inf ? "-∞" : @sprintf("%.3f", x)
    r = y == Inf ? "∞" : @sprintf("%.3f", y)
    "($l, $r)"
end

"""
    print_report(original::Candidate, rs::PiecewiseRegime; rm_ansi=false)

Output a report including a copy-pasteable function representing the `PiecewiseRegime`.
"""
function print_report(original::Candidate, rs::PiecewiseRegime; rm_ansi=false)
    box = rm_ansi ? :ASCII : :ROUNDED
    width = 80
    # table_kws = (; columns_widths=[14, 10, 52], box=box, columns_justify=[:left, :left, :left])
    table_kws = (; box=box, columns_justify=[:left, :left, :left])
    result_panel = Table(
        OrderedDict(
            :Intervals => [format_interval(r.low, r.high) for r in rs.regs],
            :Error => [biterror(r) for r in rs.regs],
            :Expression => [integerify(toexpr(r.cand)) for r in rs.regs],
        );
        footer=["Combined", "$(biterror(rs))", "%"],
        footer_justify=[:center, :left, :center],
        table_kws...,
    )

    orig_panel = Table(
        OrderedDict(
            :Interval => [format_interval(inf(rs), sup(rs))],
            :Error => [biterror(original)],
            :Expression => [toexpr(original)],
        );
        table_kws...,
    )

    expr = regimes_to_expr(rs)
    func = Expr(:function, Expr(:call, :f, expr.args[1]...), expr.args[2])
    expression_panel = Panel(highlight_syntax("$(func)"); width=width, box=box)

    header = Panel("OptiFloat Result"; justify=:center, box=:HORIZONTALS, width=width)

    na_print(x) = println(remove_ansi(string(x)))
    rm_ansi ? na_print(header) : print(header)
    println("\n  Original Expression:")
    rm_ansi ? na_print(orig_panel) : print(orig_panel)
    println("\n  Optimized PiecewiseRegime:")
    rm_ansi ? na_print(result_panel) : print(result_panel)
    println("\n  Final Expression:")
    rm_ansi ? na_print(expression_panel) : print(expression_panel)
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

function first_unused(candidates)
    for c in candidates
        if !(c.used[])
            return c
        end
    end
    error("No more unused candidates!")
end

"""
    optifloat!(candidates::Vector{<:Candidate}, points::Matrix{T}) where {T}

Try to find better candidate expressions than the ones that are already present in `candidates`.
The first unused candidate will be attempted to improve and new candidate expression are added to
`candidates`. Once a candidate is picked, this function goes through the following steps:

1. Given an initial expression `candidate`, compute the `local_error` of every
   subexpression and pick the subexpression `sub_expr` with the worst error for
   further analysis.
2. Recursively rewrite the `sub_expr` based on a _set of rewrite rules_,
   generating a number of new candidates.
3. Simplify the candidates via equality saturation (implemented in Metatheory.jl)
4. Compute error of new candidates and add every candidate that performs better
   on any of the `points` to the existing list.
"""
function optifloat!(candidates::Vector{<:Candidate}, points::Matrix{T}) where {T}
    candidate = first_unused(candidates)

    @info "Computing local error..."
    local_errs = local_biterrors(candidate.cand_expr, points)
    @info "Errors:" local_errs

    (err, worst_expr) = findmax(local_errs)
    @info "Optimizing expression with highest local error:" worst_expr err

    @info "Recursive rewrite to obtain new candidate expressions..."
    alts = recursive_rewrite(candidate.toexpr(worst_expr); depth=2)

    @info "Computing error of new candidates..."
    for (i, alt) in enumerate(alts)

        # Replace worst_expr with potentially better expressions
        reconstruct = Postwalk(PassThrough(x -> x == candidate.toexpr(worst_expr) ? alt : nothing))
        reconstructed_expr = reconstruct(toexpr(candidate))

        # Create dynamic Expression from julia Expr
        metadata = candidate.cand_expr.metadata
        new_dexpr = parse_expression(
            reconstructed_expr;
            binary_operators=metadata.operators.binops |> collect,
            unary_operators=metadata.operators.unaops |> collect,
            variable_names=metadata.variable_names,
            node_type=Node{T},
        )

        # Keep all candidates that have smaller error *somewhere*
        # Regime inference is done in another step (see: infer_regimes)
        new_candidate = Candidate(new_dexpr, candidate.orig_expr, points)
        if any([any(new_candidate.errors .< c.errors) for c in candidates])
            push!(candidates, new_candidate)
        end

        # Progress printing...
        print("\e[2K") # clear whole line
        print("\e[2G") # move cursor to column 1
        print(" ($i/$(length(alts)))  ")
        _str = repr(new_candidate)
        length(_str) > 50 ? print("$(_str[1:50])...") : print(_str)
    end
    println("")

    unique!(candidates)
    candidate.used[] = true
    sort!(candidates; by=c -> default_accum(convert(Vector{BigFloat}, c.errors)))

    return nothing
end

vnames(s::Symbol) = [string(s)]
vnames(x) = []
function vnames(e::Expr)
    leaves = mapreduce(vnames, vcat, children(e))
    chars = map(only ∘ collect, filter(s -> length(string(s)) == 1, leaves))
    unique(string.(filter(isletter, chars)))
end

"""
    parse_expression(T::Type{<:AbstractFloat}, expr::Expr; kws...)

Parse a Julia `Expr` to a dynamic `Expression` that can be used to efficiently
compute `local_error`s.
"""
function DynamicExpressions.parse_expression(
    T::Type{<:AbstractFloat},
    expr::Expr;
    binary_operators=[-, ^, /, *, +],
    unary_operators=[-, sqrt, cbrt, log, exp, abs],
    variable_names=nothing,
    node_type=Node{T},
)
    vs = isnothing(variable_names) ? vnames(expr) : variable_names
    de = parse_expression(
        expr;
        binary_operators=binary_operators,
        unary_operators=unary_operators,
        variable_names=vs,
        node_type=node_type,
    )
    (; expr=de, features=Dict(v => i for (i, v) in enumerate(vs)))
end

end
