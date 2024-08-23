module OptiFloat

export OptiFloatResult
export @optifloat, optifloat

using DynamicExpressions: Node, AbstractOperatorEnum
using DynamicExpressions
using TermInterface
using IntervalArithmetic
using Statistics: mean, median
using Metatheory: EGraph, SaturationParams, saturate!, extract!
using Metatheory.Rewriters: PassThrough, Postwalk
using Term: Table, Panel, highlight_syntax, remove_ansi
using Printf: @sprintf

"""
    Candidate{E<:Expression,A<:AbstractArray,F<:Function}

Holds an original and a candidate expression, as well as their
`biterror` and an indication if the candidate has already been used in
[`search_candidates!`](@ref) (used: ✓, unused: ⊚). Should only be constructed via one of the two
constructors below:

- `Candidate(candidate::Expr, original::Expr, points::AbstractMatrix)`
- `Candidate(candidate::Expr, points::AbstractMatrix)` (if candidate and original are the same)
"""
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

function format_interval(v, a, b)
    x = Float64(a)
    y = Float64(b)
    l = x == -Inf ? "-∞" : @sprintf("%.3f", x)
    r = y == Inf ? "∞" : @sprintf("%.3f", y)
    "$v: ($l, $r)"
end

"""
    print_report(io::IO, original::Candidate, rs::PiecewiseRegime; rm_ansi=false)

Output a report including a copy-pasteable function representing the `PiecewiseRegime`.
"""
function print_report(io::IO, original::Candidate, rs::PiecewiseRegime; rm_ansi=false)
    box = rm_ansi ? :ASCII : :ROUNDED
    width = 80
    # table_kws = (; columns_widths=[14, 10, 52], box=box, columns_justify=[:left, :left, :left])
    table_kws = (; box=box, columns_justify=[:left, :left, :left])
    vnames = original.cand_expr.metadata.variable_names
    result_panel = Table(
        OrderedDict(
            :Intervals => [format_interval(vnames[r.feature], r.low, r.high) for r in rs.regs],
            :Error => [biterror(r) for r in rs.regs],
            :Expression => [toexpr(r.cand) for r in rs.regs],
        );
        footer=length(rs.regs) > 1 ? ["Combined", "$(biterror(rs))", "%"] : nothing,
        footer_justify=[:center, :left, :center],
        table_kws...,
    )

    orig_panel = Table(
        OrderedDict(
            :Interval => [format_interval(vnames[rs.regs[1].feature], inf(rs), sup(rs))],
            :Error => [biterror(original)],
            :Expression => [toexpr(original)],
        );
        table_kws...,
    )

    expr = regimes_to_expr(rs; interval_compatible=false)
    func = Expr(:function, Expr(:call, :f, expr.args[1].args...), Expr(:block, expr.args[2]))
    expression_panel = Panel(highlight_syntax("$(func)"); width=width, box=:HORIZONTALS)

    header = Panel("OptiFloat Result"; justify=:center, box=:HORIZONTALS, width=width)

    na_print(x) = rm_ansi ? println(io, remove_ansi(string(x))) : print(io, x)
    na_print(header)
    println(io, "\n  Original Expression:")
    na_print(orig_panel)
    println(io, "\n  Optimized PiecewiseRegime:")
    na_print(result_panel)
    println(io, "\n  Improved function:")
    na_print(expression_panel)
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
    search_candidates!(candidates::Vector{<:Candidate}, points::Matrix{T}) where {T}

Try to find better candidate expressions than the ones that are already present in `candidates`.
The first unused candidate will be attempted to improve and new candidate expression are added to
`candidates`. Once a candidate is picked, this function goes through the following steps:

1. Given an initial expression `candidate`, compute the [`local_biterror`](@ref) of every
   subexpression and pick the subexpression `sub_expr` with the worst error for
   further analysis.
2. Recursively rewrite the `sub_expr` based on a _set of rewrite rules_,
   generating a number of new candidates.
3. Simplify the candidates via equality saturation (implemented in Metatheory.jl)
4. Compute error of new candidates and add every candidate that performs better
   on any of the `points` to the existing list.
"""
function search_candidates!(candidates::Vector{<:Candidate}, points::Matrix{T}) where {T}
    candidate = first_unused(candidates)

    @debug "Computing local error..."
    local_errs = local_biterrors(candidate.cand_expr, points)
    @debug "Errors:" local_errs

    (err, worst_expr) = findmax(local_errs)
    @debug "Optimizing expression with highest local error:" worst_expr err

    @debug "Recursive rewrite to obtain new candidate expressions..."
    alts = recursive_rewrite(candidate.toexpr(worst_expr); depth=2)

    @debug "Computing error of new candidates..."
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
        @debug " Candidate ($i/$(length(alts))): $new_candidate"
        # print("\e[2K") # clear whole line
        # print("\e[2G") # move cursor to column 1
        # print(" Candidate ($i/$(length(alts))):  ")
        # _str = repr(new_candidate)
        # length(_str) > 50 ? print("$(_str[1:50])...") : print(_str)
    end
    # println("")

    unique!(candidates)
    candidate.used[] = true
    sort!(candidates; by=c -> default_accum(convert(Vector{BigFloat}, c.errors)))

    return nothing
end

"""
    OptiFloatResult{O<:Expr,I<:Expr,C<:Candidate,R<:PiecewiseRegime}

## Fields
- `original::Expr`: The original expression that was attempted to be optimized.
- `improved::Expr`: The (potentially) improved expression.
- `original_candidate::Candidate`: The [`Candidate`](@ref) of the original expression. This
  struct includes the error on the sampled points.
- `improved_regimes::PiecewiseRegime`: The struct that was used to generate `improved`.
"""
struct OptiFloatResult{O<:Expr,I<:Expr,C<:Candidate,R<:PiecewiseRegime}
    original::O
    improved::I
    original_candidate::C
    improved_regimes::R
end
Base.show(io::IO, x::OptiFloatResult) = print_report(io, x.original_candidate, x.improved_regimes)

"""
    optifloat(expr::Expr, T::Type, batchsize::Int, steps::Int, interval_compatible::Bool)

The main function of OptiFloat.jl. Optimizes a floating point expression and
returns a result object which contains an improved expression.

## Example
```julia-repl
julia> using OptiFloat
julia> expr = :(sqrt(x+1) - sqrt(x))
julia> optifloat(expr; T=Float16, batchsize=100, steps=1, interval_compatible=false)
```

For more convenient usage, see [`@optifloat`](@ref)


## Arguments
- `expr::Expr`: The *floating point* expression that should be optimized.
- `T::Type{<:AbstractFloat}`: Floating point type that the expression should be evaluated on.
- `batchsize::Int`: Number of samples that OptiFloat will compute errors for. The samples are
  computed via [`logsample`](@ref) such that only samples which do not cause
  `DomainError`s/overflows are used.
- `steps::Int`: Number of times [`search_candidates!`](@ref) is called.
- `interval_compatible::Bool`: If `false` the improved function only accepts normal numbers otherwise
  the `result.improved` will be an expression that accepts `Interval`s. In the latter case you have
  to load `IntervalArithmetic`, otherwise `eval(result.improved)` will fail.

## Returns
An [`OptiFloatResult`](@ref).
"""
function optifloat(
    expr::Expr;
    T::Type=Float16,
    batchsize::Int=10_000,
    steps::Int=1,
    interval_compatible::Bool=false,
)
    dexpr, features = parse_expression(T, expr)
    points = logsample(dexpr, batchsize; eval_exact=false)
    original = Candidate(dexpr, points)
    candidates = [original]
    for _ in 1:steps
        search_candidates!(candidates, points)
    end
    (_, regimes) = map(values(features)) do f
        infer_regimes(candidates, f, points)
    end |> best_regime
    improved = regimes_to_expr(regimes; interval_compatible=interval_compatible)
    OptiFloatResult(expr, improved, original, regimes)
end

"""
    @optifloat expr kws...

The main macro of OptiFloat.jl. Optimizes a floating point expression and
returns a result object which contains an improved expression. Accepts the same
keyword arguments as [`optifloat`](@ref).

## Examples
```julia-repl
julia> using OptiFloat
julia> g = @optifloat sqrt(x+1) - sqrt(x) T=Float16 batchsize=1000
julia> g(Float16(3730))
Float16(0.00819)
```
"""
macro optifloat(expr, kws...)
    parsed_kws = _parse_kws(kws)
    res = optifloat(expr; parsed_kws...)
    res.improved
end

function _parse_kws(kws)
    # Default values for keyword arguments
    T = Float16
    batchsize = 10_000
    steps = 1
    interval_compatible = false
    for kw in kws
        if isexpr(kw) && head(kw) == :(=)
            (name, val) = children(kw)
            if name == :T
                T = eval(val)
            elseif name == :batchsize
                batchsize = val
            elseif name == :steps
                steps = val
            elseif name == :interval_compatible
                interval_compatible = val
            else
                error("$name is not an available keyword argument.")
            end
        end
    end
    (; T, batchsize, steps, interval_compatible)
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
compute [`local_biterror`](@ref)s. Convenience overload of `DynamicExpressions.parse_expression`.
"""
function DynamicExpressions.parse_expression(
    T::Type,
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
