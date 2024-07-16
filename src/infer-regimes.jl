using OptiFloat
using OptiFloat:
    biterror,
    sample_bitpattern,
    Regimes,
    evaluate_exact,
    evaluate_approx,
    Regime,
    lowleft,
    lowlefteq,
    logsample
using DynamicExpressions
using OrderedCollections: OrderedDict

function best_candidate(candidates, points, low, high)
    mask = [contains(low,p,high) for p in eachcol(points)]
    d = OrderedDict(c => mean(c.errors[mask,:]) for c in candidates)
    findmin(d)
end

minus_infsplit(s::Vector{T}) where {T} = -fill(T(Inf), length(s))
minus_infsplit(::T, index::Int) where {T} = (T(-Inf), index)
minus_infsplit(s::Tuple) = minus_infsplit(s...)
plus_infsplit(s::Vector{T}) where {T} = fill(T(Inf), length(s))
plus_infsplit(::T, index::Int) where {T} = (T(Inf), index)
plus_infsplit(s::Tuple) = plus_infsplit(s...)

function infer_regimes(
    candidates::Vector{<:Candidate}, splits::Vector{<:Vector}, points; last_point=plus_infsplit(splits[1])
) where {T}
    _best_candidate(low, high) = best_candidate(candidates, points, low, high)[2]
    _biterror(regimes::Regimes) = biterror(regimes, points)
    lowest_error(options::Vector) = findmin(Dict(r => _biterror(r) for r in options))

    inf = minus_infsplit(splits[1])
    best_split = map(enumerate(splits)) do (i, x)
        cand = _best_candidate(inf, x)
        Regimes((cand, inf, x, 0, i))
    end

    new_best_split = map(enumerate(splits)) do (i, x)
        options = map(enumerate(splits[i:end])) do (j, y)
            if OptiFloat.lowleft(x, y)
                extra_regime = Regime(_best_candidate(y, x), y, x, j, i)
                join(best_split[i], extra_regime)
            else
                best_split[i]
            end
        end
        _, best_option = lowest_error(options)
        if _biterror(best_option) + 1 < _biterror(best_split[i])
            best_option
        else
            best_split[i]
        end
    end

    full_range_split = map(new_best_split) do regimes
        high = maximum(r.high for r in regimes.regs)
        cand = _best_candidate(high, last_point)
        r = Regime(cand, high, last_point, nothing, nothing)
        join(regimes, r)
    end

    _, regs = lowest_error(full_range_split)
    return regs
end

function regimes_to_expr_1d(rs::Regimes)
    ifs = map(rs.regs) do r
        # FIXME: find better way of getting expression string to make sure
        # floats like 1.0 are actualy floats of expression type T
        s = string_tree(r.cand.cand_expr)
        expr = Meta.parse(s)
        Expr(:if, :($(only(r.low)) < x <= $(only(r.high))), :(println($s); return $expr))
    end
    Expr(:block, ifs..., :(error("Unreachable code!")))
end
