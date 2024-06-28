using OptiFloat: biterror, sample_bitpattern, Regimes, evaluate_exact, evaluate_approx
using DynamicExpressions
using OrderedCollections: OrderedDict

function infer_regimes(original, candidates, input_range, ops, T)
    points = sort(sample_bitpattern(T,input_range...,10))
    Points = reshape(sort(sample_bitpattern(T, input_range..., 1000)), 1, :)
    # original(Points,ops)
    # original(Points[:,1:1],ops)
    # evaluate_approx(original,ops,Points)
    # ys = biterror(original,ops,Points[:,1:1],accum=identity)
    # ys = biterror(original,ops,Points,accum=identity)

    function best_candidate(low, high)
        xs = reduce(hcat, filter(col->low<col[1]<=high, Points))
        d  = OrderedDict(e=>biterror(e,original,ops,xs) for e in candidates)
        display(d)
        findmin(d)[2]
    end

    regime(expr, low, high, lowindex, highindex) = (; expr=expr, low=low, high=high, li=lowindex, hi=highindex)

    function _biterror(regimes::Regimes)
        high = maximum(r.high for r in regimes.regs)
        #xs = sample_bitpattern(T,input_range[1], high,1,batchsize)
        xs = reduce(hcat, filter(col->col[1]<high, Points))
        biterror(regimes, ops, xs)
    end

    lowest_error(options::Vector) = findmin(Dict(r => _biterror(r) for r in options))[2]

    #function lowest_error(options::Vector)
    #    high = maximum(r.high for regimes in options for r in regimes.regs)
    #    xs = sample_bitpattern(T,input_range[1], high,1,batchsize)
    #    d = Dict(regimes=>biterror(regimes, original, ops, xs) for regimes in options)
    #    findmin(d)[2]
    #end

    map(zip(
        vcat(T[-Inf], points[1:end-1]),
        points
    )) do (low, high)
        best_candidate(low,high)
    end

    #_points = vcat(points, T[Inf])
    _points = points
    best_split = Any[
        Regimes([regime(best_candidate(T(-Inf),x), T(-Inf), x, 0, i)]) for (i,x) in enumerate(_points)
    ] |> vec

    #best_split = new_best_split
    #i, x = 3, points[3]
    #options = []
    #for (j,y) in enumerate(points[1:i])
    #    extra_regime = regime(best_candidate(j,i), y, x, j, i)
    #    push!(options, Regimes(vcat(best_split[j].regs, [extra_regime])))
    #end

    new_best_split = map(enumerate(_points)) do (i,x)
        options = map(enumerate(_points[1:i])) do (j,y)
            extra_regime = y<=x ? [] : [regime(best_candidate(y,x), y, x, j, i)]
            Regimes(vcat(best_split[j].regs, extra_regime))
        end
        best_option = lowest_error(options)
        #if biterror(best_option)+1 < biterror(best_split[i])
        if _biterror(best_option) < _biterror(best_split[i])
            best_option
        else
            best_split[i]
        end
    end

    full_range_split = map(new_best_split) do regimes
        high = maximum(r.high for r in regimes.regs)
        r = regime(best_candidate(high, input_range[2]), high, input_range[2], nothing, nothing)
        Regimes(vcat(regimes.regs, [r]))
    end

    regimes = lowest_error(full_range_split)
end


T = Float16
x = Node{T}(feature=1)
ops = OperatorEnum(binary_operators=[-,+,/,^,*], unary_operators=[sqrt])

original = sqrt(x+1) - sqrt(x)
candidates = [original, 1/(sqrt(x) + sqrt(x+1))]
input_range = (T(1), floatmax(T))
infer_regimes(original, candidates, input_range, ops, T)

original = -1x - sqrt(x^2-1)
candidates = [original, 1/(-1x + sqrt(x^2-1))]
input_range = (-floatmax(T), floatmax(T))
infer_regimes(original, candidates, input_range, ops, T)
