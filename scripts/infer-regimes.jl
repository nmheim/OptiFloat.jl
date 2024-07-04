using OptiFloat: biterror, sample_bitpattern, Regimes, evaluate_exact, evaluate_approx, Regime
using DynamicExpressions
using OrderedCollections: OrderedDict

function infer_regimes(original::Node{T}, ops, candidates, splits, points) where {T}
    function best_candidate(low, high)
        xs = reduce(hcat, filter(col -> low < col[1] <= high, points))
        d = OrderedDict(e => biterror(e, original, ops, xs) for e in candidates)
        findmin(d)[2]
    end

    function _biterror(regimes::Regimes)
        high = maximum(r.high for r in regimes.regs)
        low = minimum(r.low for r in regimes.regs)
        xs = reduce(hcat, filter(col -> low < col[1] <= high, points))
        @info regimes xs
        biterror(regimes, original, ops, xs)
    end

    function lowest_error(options::Vector)
        d = Dict(r => _biterror(r) for r in options)
        findmin(d)
    end

    best_split = map(enumerate(splits)) do (i, x)
        expr = best_candidate(T(-Inf), x)
        reg = Regime(expr, T(-Inf), x, 0, i)
        Regimes([reg])
    end
    @info best_split _biterror.(best_split)

    new_best_split = map(enumerate(splits)) do (i, x)
        options = map(enumerate(splits[1:i])) do (j, y)
            if y <= x
                best_split[i]
            else
                extra_regime = Regime(best_candidate(y, x), y, x, j, i)
                join(best_split[i], extra_regime)
            end
        end
        _, best_option = lowest_error(options)
        @info "new" best_option _biterror(best_option)
        if _biterror(best_option) < _biterror(best_split[i])
            best_option
        else
            best_split[i]
        end
    end

    full_range_split = map(new_best_split) do regimes
        high = maximum(r.high for r in regimes.regs)
        expr = best_candidate(high, input_range[2])
        r = Regime(expr, high, input_range[2], nothing, nothing)
        rs = Regimes(vcat(regimes.regs, [r]))
        @info "full" rs _biterror(rs)
        rs
    end

    _, regs = lowest_error(full_range_split)
    display(_biterror(Regimes(regs.regs[2:2])))
    display(_biterror(Regimes(regs.regs[1:1])))
    display(_biterror(regs))
    regs
end

T = Float16
x = Node{T}(; feature=1)
ops = OperatorEnum(; binary_operators=[-, +, /, ^, *], unary_operators=[sqrt])

#original = sqrt(x+1) - sqrt(x)
#input_range = (T(1), floatmax(T))
#splits = sort(sample_bitpattern(T,input_range...,10))
#points = reshape(sort(sample_bitpattern(T, input_range..., 1000)), 1, :)
#candidates = [original, 1/(sqrt(x) + sqrt(x+1))]
#regs = infer_regimes(original, ops, candidates, splits, points)

original = -1x - sqrt(x^2 - 1)
input_range = (-floatmax(T), floatmax(T))
#splits = sort(sample_bitpattern(T,input_range...,10))
splits = T[-1]
points = reshape(sort(sample_bitpattern(T, input_range..., 1000)), 1, :)
candidates = [original, 1 / (-1x + sqrt(x^2 - 1))]
regs = infer_regimes(original, ops, candidates, splits, points)
