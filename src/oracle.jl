using TermInterface: maketerm, iscall, arguments, operation
using IntervalArithmetic: interval, bounds, isthin, mid
using Statistics: mean


_inttype(::Type{Float16}) = Int16
_inttype(::Type{Float32}) = Int32
_inttype(::Type{Float64}) = Int64

function ulpdistance(a::F, b::F) where F<:AbstractFloat
    T = _inttype(F)
    a == b && return zero(T)
    isnan(a) || isnan(b) && return typemax(T)
    isinf(a) || isinf(b) && return typemax(T)
    
    a_int = reinterpret(T, a)
    b_int = reinterpret(T, b)

    (a_int < 0) != (b_int < 0) && return typemax(T)

    @info "ulp" a b typeof(a_int) typeof(b_int)
    return abs(a_int - b_int)
end
#function ulpdistance(a::F, b::BigFloat) where F<:AbstractFloat
#    a == b && return 0
#    T = _inttype(F)
#    isnan(a) || isnan(b) && return BigInt(typemax(T))
#    isinf(a) || isinf(b) && return BigInt(typemax(T))
#    
#    a_int = reinterpret(T, a)
#    b_int = tobigint(b)
#
#    (a_int < 0) != (b_int < 0) && return BigInt(typemax(T))
#
#    return abs(a_int - b_int)
#end

function biterror(f, args::T...; kw...) where T<:AbstractFloat
    y_exact = evaluate_exact(f, args...; kw...)
    y_approx = try
        f(args...)
    catch e
        if e isa DomainError
            T(NaN)
        else
            rethrow(e)
        end
    end
    ulps = ulpdistance(y_approx, convert(T,y_exact))
    T(ulps==0 ? 0 : log2(ulps))
end
function biterror(expr::Expr, point::Point; kw...)
    g = lambdify(expr, keys(point)...)
    biterror(g, values(point)...; kw...)
end

function biterrorscore(f, args::T...; kw...) where T<:AbstractFloat
    err = biterror(f, args...; kw...)
    score = 1 - (err / (sizeof(T)*8))
    convert(T, score)
end

isconst(::Expr) = false
isconst(::Symbol) = true
isconst(::Number) = true
function subfunctions(expr::Expr, args::Symbol...)
    exprs = filter(!isconst, all_subexpressions(expr))
    Dict(e=>lambdify(e, args...) for e in exprs)
end

function all_subexpressions(expr::Expr)
    subs = if iscall(expr)
        vcat([expr], reduce(vcat, all_subexpressions.(arguments(expr))))
    else
        [expr]
    end
    unique(subs)
end
all_subexpressions(x) = [x]

local_biterror(x::Number, point::Point{syms,N,T}) where {syms,N,T}= BigInt(0)
local_biterror(x::Symbol, point::Point{syms,N,T}) where {syms,N,T}= BigInt(0)
local_biterror(x::Number, point::Batch{syms,N,T}) where {syms,N,T}= BigInt(0)
local_biterror(x::Symbol, point::Batch{syms,N,T}) where {syms,N,T}= BigInt(0)


maximum_precision(::Int) = 0
maximum_precision(x::AbstractFloat) = precision(x)
maximum_precision(fs::Vector) = maximum(maximum_precision.(fs))

function local_biterror(expr, point::Point{syms,N,T}) where {syms,N,T}
    localf = iscall(expr) ? eval(operation(expr)) : error("not a call")

    exact_args = [evaluate_exact(a, point) for a in arguments(expr)]
    prec = maximum_precision(exact_args)

    approx_args = convert(Vector{T}, exact_args)
    approx_result = localf(approx_args...)

    exact_args = [BigFloat(x,prec) for x in exact_args]
    exact_result = evaluate_exact(localf, exact_args...)

    ulpdistance(approx_result, convert(T, exact_result))
end

convert_args(T::Type{<:AbstractFloat}, arg::Number) = convert(T,arg)
convert_args(T::Type{<:AbstractFloat}, args::Vector) = convert_args.(T,args)

function local_biterror(expr, batch::Batch{syms,N,T}; accum=mean) where {syms,N,T}
    localf = iscall(expr) ? eval(operation(expr)) : error("not a call")

    # each BigFloat from evaluate_exact might have different precision
    exact_args = [evaluate_exact(a, batch) for a in arguments(expr)]
    prec = maximum_precision(exact_args)

    approx_args = convert_args(T, exact_args)
    approx_result = localf.(approx_args...)

    exact_args = [BigFloat.(x,prec) for x in exact_args]
    exact_result = evaluate_exact.(localf, exact_args...)
    setprecision(prec) do
        accum(ulpdistance.(approx_result, convert(Vector{T}, exact_result)))
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
