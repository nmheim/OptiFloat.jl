using OptiFloat
using OptiFloat:
    biterror,
    sample_bitpattern,
    PiecewiseRegime,
    evaluate_exact,
    evaluate_approx,
    Regime,
    lowleft,
    lowlefteq,
    logsample
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

function infer_regimes(
    candidates::Union{Vector{<:Candidate}, Vector{<:Regime}},
    splits::Vector{<:Number},
    feature::Int,
    points::Matrix{T};
    infimum=T(-Inf),
    supremum=T(Inf),
) where T
    function _best_regime(low, high)
        rs = regimes(candidates, points, low, high, feature)
        d = OrderedDict(r=>biterror(r) for r in rs)
        findmin(d)[2]
    end

    best_split = Dict(
        0 => nothing,
        1 => OrderedDict(x => PiecewiseRegime([_best_regime(infimum, x)]) for x in vcat(splits, [supremum]))
    )

    n = 0
    while best_split[n] != best_split[n+1]
        n+=1
        best_split[n+1] = typeof(best_split[n])()
        options = OrderedDict()
        for x in vcat(splits, [supremum])
            for y in filter(y->y<x, splits)
                if y < x
                    extra_regime = _best_regime(y,x)
                    options[y] = join(best_split[n][y], extra_regime)
                end
            end
            best = if length(options) > 0
                findmin(OrderedDict(opt=>biterror(opt) for opt in values(options)))[2]
            else
                best_split[n][x]
            end
            best_split[n+1][x] = best
 
            if biterror(best_split[n][x])-1 <= biterror(best_split[n+1][x])
                best_split[n+1][x] = best_split[n][x]
            end
        end
    end
    best_split[n+1][supremum]
end

function regimes_to_expr_1d(rs::PiecewiseRegime)
    ifs = map(rs.regs) do r
        # FIXME: find better way of getting expression string to make sure
        # floats like 1.0 are actualy floats of expression type T
        s = string_tree(r.cand.cand_expr)
        expr = Meta.parse(s)
        Expr(:if, :($(only(r.low)) < x <= $(only(r.high))), :(println($s); return $expr))
    end
    Expr(:block, ifs..., :(error("Unreachable code!")))
end
