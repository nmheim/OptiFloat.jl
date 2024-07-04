using OptiFloat
using OptiFloat: biterror, sample_bitpattern, Regimes, evaluate_exact, evaluate_approx, Regime,
    lowleft, lowlefteq, logsample
using DynamicExpressions
using OrderedCollections: OrderedDict


function best_candidate(target, candidates, ops, points, low, high)
    # xs = reduce(hcat, filter(col->low<col[1]<=high, points))
    xs = reduce(hcat, filter(p -> contains(low,p,high), eachcol(points)))
    d  = OrderedDict(e=>biterror(e,target,ops,xs) for e in candidates)
    findmin(d)
end

minus_infsplit(s::Vector{T}) where T = -fill(T(Inf), length(s))
minus_infsplit(::T, index::Int) where T = (T(-Inf), index)
minus_infsplit(s::Tuple) = minus_infsplit(s...)
plus_infsplit(s::Vector{T}) where T = fill(T(Inf), length(s))
plus_infsplit(::T, index::Int) where T = (T(Inf), index)
plus_infsplit(s::Tuple) = plus_infsplit(s...)

function infer_regimes(
    original::Expression{T}, candidates, splits, points;
    last_point=plus_infsplit(splits[1])
) where T

    function _best_candidate(low,high)
        ops = original.metadata.operators
        vars = original.metadata.variable_names
        (_, c) = best_candidate(
            original.tree,
            [c.tree for c in candidates],
            ops, points, low, high
        )
        Expression(c, operators=ops, variable_names=vars)
    end

    function _biterror(regimes::Regimes)
        xs = reduce(hcat, filter(p -> contains(regimes,p), eachcol(points)))
        biterror(regimes, original, xs)
    end

    function lowest_error(options::Vector)
        d = Dict(r => _biterror(r) for r in options)
        findmin(d)
    end


    inf = minus_infsplit(splits[1])
    best_split = map(enumerate(splits)) do (i,x)
        expr = _best_candidate(inf, x)
        reg = Regime(expr, inf, x, 0, i)
        Regimes([reg])
    end
    _biterror.(best_split)

    new_best_split = map(enumerate(splits)) do (i,x)
        options = map(enumerate(splits[1:i])) do (j,y)
            if OptiFloat.lowleft(x,y)
                extra_regime = Regime(_best_candidate(y,x), y, x, j, i)
                join(best_split[i], extra_regime)
            else
                best_split[i]
            end
        end
        _, best_option = lowest_error(options)
        if _biterror(best_option)+1 < _biterror(best_split[i])
            best_option
        else
            best_split[i]
        end
    end

    full_range_split = map(new_best_split) do regimes
        high = maximum(r.high for r in regimes.regs)
        expr = _best_candidate(high, last_point)
        r = Regime(expr, high, last_point, nothing, nothing)
        Regimes(vcat(regimes.regs, [r]))
    end

    for r in full_range_split
        print(_biterror(r))
        print(" ")
        display(r)
    end
    _, regs = lowest_error(full_range_split)
    return regs
end


T = Float16
orig_expr = :((-b - sqrt(b^2 - (4*c))) / (2*c))
candidate = :(2 / (-b + sqrt((b ^ 2.0) - (4.0 * c))))
kws = (;
    variable_names = ["c", "b"],
    binary_operators = [-, *, /, ^, +],
    unary_operators = [-, sqrt],
    node_type=Node{T}
)
dexpr = parse_expression(orig_expr; kws...)
c_dexpr = parse_expression(candidate; kws...)
candidates = [dexpr, c_dexpr]

fmax = fill(floatmax(T), 2)
#points = sample_bitpattern(T, -floatmax(T), floatmax(T), 2, 1000)
points = logsample(dexpr, T, 2, 1000)
points = reduce(hcat, sort(eachcol(points), lt=OptiFloat.lowleft))

splits = sort([
    T[-1e3, -1e3],
    T[-1e2, -1e2],
    T[-1e1, -1e1],
    T[   0,    0],
    T[ 1e0,  1e0],
    T[ 1e1,  1e1],
    T[ 1e2,  1e2],
    T[ 1e3,  1e3],
    T[   0, -1e3],
    T[   0, -1e2],
    T[   0, -1e1],
    T[   0,    0],
    T[   0,  1e0],
    T[   0,  1e1],
    T[   0,  1e2],
    T[   0,  1e3],
], lt=OptiFloat.lowlefteq)
regs = infer_regimes(dexpr, candidates, splits, points)
display(regs)
println("")

splits = [
    (T(-1e3), 2),
    (T(-1e2), 2),
    (T(-1e1), 2),
    (T(-1e0), 2),
    (T( 1e1), 2),
    (T( 1e2), 2),
    (T( 1e3), 2),
]
regs = infer_regimes(dexpr, candidates, splits, points)
display(regs)
println("")

splits = [
    (T(-1e3), 2),
    (T(-1e2), 2),
    (T(-1e1), 2),
    (T(-1e0), 2),
    (T( 1e1), 2),
    (T( 1e2), 2),
    (T( 1e3), 2),
]
regs = infer_regimes(dexpr, candidates, splits, points)


# biterror(dexpr.tree, c_dexpr.tree, dexpr.metadata.operators, points) |> display

