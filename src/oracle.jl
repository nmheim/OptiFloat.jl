using TermInterface: maketerm, iscall, arguments, operation
using IntervalArithmetic: interval, bounds, isthin, mid
using Statistics: mean

const Point{syms,N,T} = NamedTuple{syms, <:NTuple{N,T}} where {syms,N,T<:Real}
const Batch{syms,N,T} = NamedTuple{syms, <:NTuple{N,Vector{T}}} where {syms,N,T<:Real}

function evaluate_exact(f, args::Union{<:Number,Int}...; init_precision=initprec(args...), max_precision=500)

    # need to check precision on values here, because BigFloat does not have precision in type
    @assert length(unique(precision.(filter(a->!(a isa Integer), args)))) == 1 "All inputs must have same precision!"

    # compute interval for higher precision
    precision_interval = setprecision(init_precision) do
        intervals = interval.(BigFloat.(args))
        f(intervals...)
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

function evaluate_exact(expr::Expr, point::Union{<:Point,<:Batch}; kw...)
    g = lambdify(expr, keys(point)...)
    evaluate_exact.(g, values(point)...; kw...)
end
evaluate_exact(x::Symbol, p::Union{<:Point,<:Batch}; kw...) = p[x]
evaluate_exact(x::Number, p::Union{<:Point,<:Batch}; kw...) = x

evaluate(expr, point::Point) = lambdify(expr, keys(point)...)(values(point)...)

function accuracy(f, args...; kw...)
    y_exact = evaluate_exact(f, args...; kw...)
    y_approx = try
        f(args...)
    catch e
        if e isa DomainError
            # TODO: return correct NaN type, e.g. NaN16
            NaN
        else
            rethrow(e)
        end
    end
    y = setprecision(y_exact.prec) do
        1 - abs((y_approx - y_exact) / max(y_approx, y_exact))
    end
    out = convert(typeof(y_approx), y)
    # converts NaNs/Infs to zero... do we want that?
    isfinite(out) ? out : zero(typeof(y_approx))
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

local_error(x::Number, point::Union{<:Point,<:Batch}) = BigFloat(0)
local_error(x::Symbol, point::Union{<:Point,<:Batch}) = BigFloat(0)

maximum_precision(::Int) = 0
maximum_precision(x::AbstractFloat) = precision(x)
maximum_precision(fs::Vector) = maximum(maximum_precision.(fs))

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

convert_args(T::Type{<:AbstractFloat}, arg::Number) = convert(T,arg)
convert_args(T::Type{<:AbstractFloat}, args::Vector) = convert_args.(T,args)

function local_error(expr, batch::Batch{syms,N,T}; accum=mean) where {syms,N,T}
    localf = iscall(expr) ? eval(operation(expr)) : error("not a call")

    # each BigFloat from evaluate_exact might have different precision
    exact_args = [evaluate_exact(a, batch) for a in arguments(expr)]
    prec = maximum_precision(exact_args)

    approx_args = convert_args(T, exact_args)
    approx_result = localf.(approx_args...)

    exact_args = [BigFloat.(x,prec) for x in exact_args]
    exact_result = evaluate_exact.(localf, exact_args...)
    setprecision(prec) do
        mean(abs, approx_result - exact_result)
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

