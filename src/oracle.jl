using TermInterface: maketerm, iscall, arguments, operation
using IntervalArithmetic: interval, bounds, isthin, mid

const Point{syms,N,T} = NamedTuple{syms, <:NTuple{N,T}} where {syms,N,T<:Real}

function evaluate_exact(f, args::Union{<:Number,Int}...; init_precision=initprec(args...), max_precision=500)

    # need to check precision on values here, because BigFloat does not have precision in type
    @assert length(unique(precision.(filter(a->!(a isa Integer), args)))) == 1 "All inputs must have same precision!"

    # compute interval for higher precision
    precision_interval, precision_interval_is_thin = setprecision(init_precision) do
        intervals = interval.(BigFloat.(args))
        y = f(intervals...)
        y, isthin(y)
    end

    # check if we found an interval that only contains one number 𝑅𝑝(𝑦1) = 𝑦∗ = 𝑅𝑝(𝑦2)
    new_precision = init_precision * 2
    if isthin(precision_interval) || new_precision > max_precision
        setprecision(init_precision) do
            mid(precision_interval)
        end
    else
        evaluate_exact(f, args..., init_precision=new_precision)
    end
end

function evaluate_exact(expr::Expr, point::Point; kw...)
    g = lambdify(expr, keys(point)...)
    evaluate_exact(g, values(point)...; kw...)
end
evaluate_exact(x::Symbol, p::Point; kw...) = p[x]
evaluate_exact(x::Number, p::Point; kw...) = x

evaluate(expr, point::Point) = lambdify(expr, keys(point)...)(values(point)...)

function accuracy(f, args...; kw...)
    y_exact = evaluate_exact(f, args...; kw...)
    y_approx = f(args...)
    y = setprecision(y_exact.prec) do
        abs(y_approx - y_exact)
    end
    convert(typeof(y_approx), y)
end
function accuracy(expr::Expr, point::Point; kw...)
    g = lambdify(expr, keys(point)...)
    accuracy(g, values(point)...; kw...)
end

function all_subexpressions(expr)
    subs = if iscall(expr)
        vcat([expr], reduce(vcat, all_subexpressions.(arguments(expr))))
    else
        [expr]
    end
    unique(subs)
end

local_error(x::Number, point::Point) = BigFloat(0)
local_error(x::Symbol, point::Point) = BigFloat(0)

maximum_precision(fs::Vector{BigFloat}) = maximum(precision.(fs))
maximum_precision(fs) = maximum(precision(f) for f in fs if !(f isa Int))

function local_error(expr, point::Point{syms,N,T}) where {syms,N,T}
    localf = iscall(expr) ? eval(operation(expr)) : error("not a call")

    # each BigFloat from evaluate_exact might have different precision
    exact_args = [evaluate_exact(a, point) for a in arguments(expr)]
    prec = maximum_precision(exact_args)

    approx_args = convert(Vector{T}, exact_args)
    approx_result = localf(approx_args...)

    exact_args = [BigFloat(x,prec) for x in exact_args]
    exact_result = evaluate_exact(localf, exact_args...)
    setprecision(prec) do 
        abs(approx_result - exact_result)
    end
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

