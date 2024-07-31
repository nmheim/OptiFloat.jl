using OptiFloat
using OptiFloat:
    biterror, sample_bitpattern, PiecewiseRegime, evaluate_exact, evaluate_approx, Regime, logsample
using DynamicExpressions
using OrderedCollections: OrderedDict

function regime(candidate, points, low, high, feature)
    mask = [low < p[feature] <= high for p in eachcol(points)]
    Regime(candidate, low, high, feature, mask)
end
function regimes(candidates, points, low, high, feature)
    mask = [low < p[feature] <= high for p in eachcol(points)]
    [Regime(c, low, high, feature, mask) for c in candidates]
end

IntervalArithmetic.sup(r::Regime) = r.high
IntervalArithmetic.inf(r::Regime) = r.low
IntervalArithmetic.sup(r::PiecewiseRegime) = maximum(r.high for r in r.regs)
IntervalArithmetic.inf(r::PiecewiseRegime) = minimum(r.low for r in r.regs)

function default_splits(points::AbstractMatrix{T}, feature::Int, n::Int) where {T}
    (mi, ma) = BigFloat(minimum(points[feature, :])), BigFloat(maximum(points[feature, :]))
    if mi < 0 && ma > 0
        n_neg_splits = round(Int, abs(mi) * n / (abs(mi) + ma))
        n_pos_splits = round(Int, ma * n / (abs(mi) + ma))
        negative_splits = -logrange(1e-2, abs(mi), n_neg_splits)
        positive_splits = logrange(1e-2, ma, n_pos_splits)
        T.(vcat(reverse(negative_splits), positive_splits))
    elseif mi < 0 && ma < 0
        T.(reverse(-logrange(abs(ma), abs(mi), n)))
    else
        T.(logrange(mi, ma, n))
    end
end

best_regime(regimes::Vector) = findmin(OrderedDict(r => biterror(r) for r in regimes))

"""
    infer_regimes(candidates::Vector{<:Candidate}, feature::Int, points::Matrix{T}; kws...)

Pick as few candidates and their corresponding good regimes to define a `PiecewiseRegime` that
represents an expression that performs well on all `points`.
"""
function infer_regimes(
    candidates::Union{Vector{<:Candidate},Vector{<:Regime}},
    feature::Int,
    points::Matrix{T};
    infimum=T(-Inf),
    supremum=T(Inf),
    splits::Vector{<:Number}=default_splits(points, feature, 10),
) where {T}
    function _best_regime(low, high)
        rs = regimes(candidates, points, low, high, feature)
        best_regime(rs)[2]
    end

    best_split = Dict(
        0 => nothing,
        1 => OrderedDict(
            x => PiecewiseRegime([_best_regime(infimum, x)]) for x in vcat(splits, [supremum])
        ),
    )

    n = 0
    while best_split[n] != best_split[n + 1]
        n += 1
        best_split[n + 1] = typeof(best_split[n])()
        options = OrderedDict()
        for x in vcat(splits, [supremum])
            for y in filter(y -> y < x, splits)
                if y < x
                    extra_regime = _best_regime(y, x)
                    options[y] = join(best_split[n][y], extra_regime)
                end
            end
            best = if length(options) > 0
                findmin(OrderedDict(opt => biterror(opt) for opt in values(options)))[2]
            else
                best_split[n][x]
            end
            best_split[n + 1][x] = best

            if biterror(best_split[n][x]) - 1 <= biterror(best_split[n + 1][x])
                best_split[n + 1][x] = best_split[n][x]
            end
        end
    end
    best_split[n + 1][supremum]
end

function regimes_to_expr(rs::PiecewiseRegime; interval_compatible=false)
    body = if length(rs.regs) == 1
        toexpr(rs.regs[1].cand)
    elseif interval_compatible
        @info "If you want Interval compatible functions (e.g. to use with `evaluate_exact`) make sure to include `using IntervalArithmetic` in your file."
        num_contains = :(_in(low, x::Number, high) = low < x <= high)
        interval_contains =
            :(_in(low, x::Interval, high) = issubset_interval(x, interval(low, high)))
        ifs = map(rs.regs) do r
            expr = toexpr(r.cand)
            x = Symbol(r.cand.cand_expr.metadata.variable_names[r.feature])
            (l, h) = only(r.low), only(r.high)
            Expr(:if, :(_in($l, $x, $h)), :(return $expr))
        end
        Expr(:block, num_contains, interval_contains, ifs..., :(error("Unreachable code!")))
    else
        ifs = map(rs.regs) do r
            expr = toexpr(r.cand)
            x = Symbol(r.cand.cand_expr.metadata.variable_names[r.feature])
            (l, h) = only(r.low), only(r.high)
            Expr(:if, :($l < $x <= $h), expr)
        end
        Expr(:block, ifs...)
    end
    expr = rs.regs[1].cand.orig_expr
    vars = expr.metadata.variable_names
    Expr(:->, Expr(:tuple, Symbol.(vars)...), body)
end
