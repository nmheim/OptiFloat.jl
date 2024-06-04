using TermInterface: maketerm, iscall, arguments, operation
using IntervalArithmetic: interval, bounds, isthin, mid

function evaluate_exact(f, args::Union{<:Number,Int}...; init_precision=initprec(args...), max_precision=500)

    # need to check precision on values here, because BigFloat does not have precision in type
    @assert length(unique(precision.(filter(a->!(a isa Integer), args)))) == 1 "All inputs must have same precision!"

    # compute interval for higher precision
    precision_interval, precision_interval_is_thin = setprecision(init_precision) do
        intervals = interval.(BigFloat.(args))
        y = f(intervals...)
        @info intervals f args f(args...) y bounds(y) bounds(y)[1].prec isthin(y)
        y, isthin(y)
    end

    # round to target precision
    T = floattype(args...)
    #(a,b) = bounds(precision_interval)
    #result_interval = setprecision(precision(T)) do
    #    # FIXME: is this the correct way of getting the target precision interval?
    #    interval(BigFloat(round(a, RoundDown)), BigFloat(round(b, RoundUp)))
    #    #interval(BigFloat(round(a)), BigFloat(round(b)))
    #end

    # check if we found an interval that only contains one number 𝑅𝑝(𝑦1) = 𝑦∗ = 𝑅𝑝(𝑦2)
    new_precision = init_precision * 2
    @info new_precision
    if precision_interval_is_thin || new_precision > max_precision
        #precision_convert(T, mid(precision_interval))
        setprecision(new_precision) do
            mid(precision_interval)
        end
    else
        evaluate_exact(f, args..., init_precision=new_precision)
    end
end
function evaluate_exact(expr::Expr, point::Tuple{Symbol,<:Number}...; kw...)
    inputs, values = zip(point...)
    g = lambdify(expr, inputs...)
    evaluate_exact(g, values...; kw...)
end
function evaluate_exact(x::Symbol, point::Tuple{Symbol,<:Number}...; kw...)
    Dict(k=>v for (k,v) in point)[x]
end
evaluate_exact(x::Number, point...; kw...) = x


function accuracy(f, args::T...; kw...) where T
    setprecision(precision(args[1])) do
        abs(f(args...) - evaluate_exact(f, args..., kw...))
    end
end

function all_subexpressions(expr)
    subs = if iscall(expr)
        vcat([expr], reduce(vcat, all_subexpressions.(arguments(expr))))
    else
        [expr]
    end
    unique(subs)
end

local_error(x::Number, point::Tuple{Symbol,<:Number}...) = 0
local_error(x::Symbol, point::Tuple{Symbol,<:Number}...) = 0

function local_error(expr, point::Tuple{Symbol,<:Number}...)
    exact_args = collect(evaluate_exact(a, point...) for a in arguments(expr))
    localf = iscall(expr) ? eval(operation(expr)) : error("not a call")
    approx_result = localf(exact_args...)
    exact_result = evaluate_exact(localf, exact_args...)
    abs(approx_result - exact_result)
end

function lambdify(expr, args...)
    # TODO: surely there is a better way of doing this
    # TODO: look at DynamicExpressions.jl ? 
    fexpr = Expr(:->, Expr(:tuple, args...), expr)
    f = eval(fexpr)
    g(xs...) = Base.invokelatest(f, xs...)
    g
end

precision_convert(::Type{T}, x) where T = convert(T,x)
precision_convert(t::T, x) where T<:Real = convert(T,x)
precision_convert(t::BigFloat, x) = BigFloat(x,precision=t.prec)

function floattype(xs::Number...)
    number_types = unique(typeof.(xs))
    @assert length(number_types) <= 2
    filter(t->!(t <: Integer), number_types) |> first
end
initprec(xs...) = precision(floattype(xs...)) + 1

