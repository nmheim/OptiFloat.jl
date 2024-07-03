using OptiFloat
using OptiFloat: biterror, sample_bitpattern, Regimes, evaluate_exact, evaluate_approx, Regime,
    lowleft, lowlefteq
using DynamicExpressions
using OrderedCollections: OrderedDict


function best_candidate(target, candidates, ops, points, low, high)
    # xs = reduce(hcat, filter(col->low<col[1]<=high, points))
    xs = reduce(hcat, filter(p -> contains(low,p,high), eachcol(points)))
    d  = OrderedDict(e=>biterror(e,target,ops,xs) for e in candidates)
    @info "best" low high d
    findmin(d)
end



function infer_regimes(
    original::Expression{T}, candidates, splits, points;
    last_point=fill(T(Inf), size(points,1))
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


    inf = fill(T(Inf), size(points,1))
    best_split = map(enumerate(eachcol(splits))) do (i,x)
        expr = _best_candidate(-inf, x)
        reg = Regime(expr, -inf, x, 0, i)
        Regimes([reg])
    end
    _biterror.(best_split)

    new_best_split = map(enumerate(eachcol(splits))) do (i,x)
        options = map(enumerate(eachcol(splits[1:i]))) do (j,y)
            if y <= x
                best_split[i]
            else
                extra_regime = Regime(_best_candidate(y,x), y, x, j, i)
                join(best_split[i], extra_regime)
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

fmax = fill(floatmax(T), 2)
splits = T[
    -1000 -10 -1 0 1 10 100 1000
    -1000 -10 -1 0 1 10 100 1000
]
# FIXME: commenting out the additional splits below makes things crash
splits = T[
        0   0  0 0 0  0   0    0 #-1000 -10 -1 0 1 10 100 1000
    -1000 -10 -1 0 1 10 100 1000 #-1000 -10 -1 0 1 10 100 1000
]
points = sample_bitpattern(T, -floatmax(T), floatmax(T), 2, 1000)
points = reduce(hcat, sort(eachcol(points), lt=OptiFloat.lowleft))

biterror(dexpr.tree, c_dexpr.tree, dexpr.metadata.operators, points) |> display

candidates = [dexpr, c_dexpr]
regs = infer_regimes(dexpr, candidates, splits, points)
