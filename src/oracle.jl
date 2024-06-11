using TermInterface: maketerm, iscall, arguments, operation
using IntervalArithmetic: interval, bounds, isthin, mid
using Statistics: mean

const Point{syms,N,T} = NamedTuple{syms, <:NTuple{N,T}} where {syms,N,T<:Real}
const Batch{syms,N,T} = NamedTuple{syms, <:NTuple{N,Vector{T}}} where {syms,N,T<:Real}

function evaluate_exact(f, args::Union{<:Number,Int}...; init_precision::Int=initprec(args...), max_precision::Int=1500)

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

_inttype(::Type{Float16}) = Int16
_inttype(::Type{Float32}) = Int32
_inttype(::Type{Float64}) = Int64

#function ulpdistance(a::F, b::F) where F
#    T = _inttype(F)
#    a_ = -0.0 === a ? reinterpret(T, F(0.0)) : reinterpret(T, a)
#    b_ = -0.0 === b ? reinterpret(T, F(0.0)) : reinterpret(T, b)
#    abs(a_ - b_)
#end
#function ulpdistance(a::BigFloat, b::BigFloat)
#    @assert a.prec == b.prec
#    abs(tobigint(a) - tobigint(b))
#end
function ulpdistance(a::F, b::F) where F<:AbstractFloat
    a == b && return 0
    T = _inttype(F)
    isnan(a) || isnan(b) && return typemax(T)
    isinf(a) || isinf(b) && return typemax(T)
    
    a_int = reinterpret(T, a)
    b_int = reinterpret(T, b)

    (a_int < 0) != (b_int < 0) && return typemax(T)

    return abs(a_int - b_int)
end
function ulpdistance(a::F, b::BigFloat) where F<:AbstractFloat
    a == b && return 0
    T = _inttype(F)
    isnan(a) || isnan(b) && return BigInt(typemax(T))
    isinf(a) || isinf(b) && return BigInt(typemax(T))
    
    a_int = reinterpret(T, a)
    b_int = tobigint(b)

    (a_int < 0) != (b_int < 0) && return BigInt(typemax(T))

    return abs(a_int - b_int)
end

exposize(::Type{Float16}) = 5
exposize(::Type{Float32}) = 8
exposize(::Type{Float64}) = 11
maxulp(::Type{T}) where T<:AbstractFloat = 2^precision(T) * exposize(T)

function errorscore(f, args::Number...; kw...)
    y_exact = evaluate_exact(f, args...; kw...)
    T = floattype(args...)
    y_approx = try
        f(args...)
    catch e
        if e isa DomainError
            #BigFloat(NaN)
            T(NaN)
        else
            rethrow(e)
        end
    end

    #ulps = 1 + ulpdistance(y_approx, y_exact)
    ulps = ulpdistance(y_approx, convert(T,y_exact))
    err = ulps==0 ? 0 : log2(ulps)
    1 - (err / (sizeof(T)*8))
end

function accuracy(f, args::Number...; kw...)
    y_exact = evaluate_exact(f, args...; kw...)
    y_approx = try
        f(args...)
    catch e
        if e isa DomainError
            BigFloat(NaN)
        else
            rethrow(e)
        end
    end
    if isfinite(y_approx)
        # special case close to zero
        T = typeof(y_approx)
        ε = eps(T)
        if (-ε < y_approx < ε) && (-ε < y_exact < ε)
            BigFloat(1)
        else
            setprecision(y_exact.prec) do
                acc = 1 - abs((y_approx - y_exact) / maximum(abs.([y_approx, y_exact])))
                max(acc, 0)
            end :: BigFloat
        end
    else
        BigFloat(0, y_exact.prec)
    end
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

