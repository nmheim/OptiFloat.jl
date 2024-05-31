using TermInterface
using IntervalArithmetic
using OptiFloat

#expr = :(a + b * (c + a))
expr = :(a + b)
intervals = Dict(
    :a => interval(-1e10,1e10),
    :b => interval(-1e10,1e10),
)

#expr = :((1 / (x+1) - (2/x)) + (1/x+1))
expr = :(1 / (x+1) - (2/x))
x = Float16(1e2)
f(x) = (1/(x-1) - 2/x) #+ (1/x+1)

expr = :(x^y / (x^y + 2))
f(x,y) = x^y / (x^y + 2)
T = Float16
x = T(-1.1)
y = T(7.0)
x = T(3.0)
y = T(1.1)
point = ((:x, x), (:y, y))

intervals = Dict(
    :x => interval(T(1.0),T(4.0)),
    :y => interval(T(0.5),T(7.0)),
)

function sample(x::Interval{T}, batchsize::Int) where T
    # TODO: sample random bits in the interval in stead of uniform dist
    # TODO: make sure we can sample from (-Inf,Inf)
    (a,b) = bounds(x)
    rand(T, batchsize) .* (b-a) .+ a
end
function sample(x::Dict{Symbol,<:Interval}, batchsize::Int)
    dict = Dict(k=>sample(i,batchsize) for (k,i) in x)
    (zip(keys(x), p) for p in zip(values(dict)...))
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

function local_error(expr, intervals, batchsize=100)
    points = sample(intervals, batchsize)
    map(points) do point
        local_error(expr, point...)
    end
end


# this should not return all zeros... something wrong with how
# evaluate_exact/localf are computed in local_error....
map(e->local_error(e,(:x,x)), all_subexpressions(expr))
