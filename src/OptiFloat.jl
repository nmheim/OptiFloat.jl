module OptiFloat

using IntervalArithmetic: interval, bounds, isthin, mid

export accurate_result, accuracy

precision_convert(::Type{T}, x) where T = convert(T,x)
precision_convert(t::T, x) where T = convert(T,x)
precision_convert(t::BigFloat, x) = BigFloat(x,precision=t.prec)

function accurate_result(f, x::T, xs::T...; init_precision=precision(x)+1, max_precision=500) where T
    args = (x, xs...)
    @assert length(unique(precision.(args))) == 1 "All inputs must have same precision!"

    # compute interval for higher precision
    precision_interval = setprecision(init_precision) do
        intervals = interval.(BigFloat.(args))
        f(intervals...)
    end

    # round to target precision
    result_interval = setprecision(precision(T)) do
        interval(BigFloat.(bounds(precision_interval)))
    end

    # check if we found an interval that only contains one number 𝑅𝑝(𝑦1) = 𝑦∗ = 𝑅𝑝(𝑦2)
    new_precision = init_precision * 2
    if isthin(result_interval) || new_precision > max_precision
        precision_convert(x, mid(result_interval))
    else
        accurate_result(f, args..., init_precision=new_precision)
    end
end

function accuracy(f, args::T...; kw...) where T
    setprecision(precision(args[1])) do
        abs(f(args...) - accurate_result(f, args..., kw...))
    end
end


end # module OptiFloat
