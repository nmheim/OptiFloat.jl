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


function regimes(candidates, points, low, high, feature)
    mask = [low < p[feature] <= high for p in eachcol(points)]
    [Regime(c, low, high, feature, mask) for c in candidates]
end

function infer_regimes(
    candidates::Union{Vector{<:Candidate}, Vector{<:Regime}},
    splits::Vector{<:Number},
    feature::Int,
    points::Matrix{T};
    supremum=T(Inf),
) where T
    function _best_regime(low, high)
        rs = regimes(candidates, points, low, high, feature)
        d = OrderedDict(r=>biterror(r) for r in rs)
        findmin(d)[2]
    end
    lowest_error(options::Vector) = findmin(OrderedDict(r => biterror(r) for r in options))

    best_split = [PiecewiseRegime([_best_regime(T(-Inf), x)]) for x in splits]

    new_best_split = map(enumerate(splits)) do (i,x)
        options = map(splits[i:end]) do y
            x<y ? join(best_split[i], _best_regime(x,y)) : best_split[i]
        end
        _, best_option = lowest_error(options)
        biterror(best_option)+1 < biterror(best_split[i]) ? best_option : best_split[i]
    end

    full_range_split = map(new_best_split) do regimes
        high = maximum(r.high for r in regimes.regs)
        r = _best_regime(high, supremum)
        join(regimes, r)
    end

    _, regs = lowest_error(full_range_split)
    return regs
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
