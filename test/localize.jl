using TermInterface
using IntervalArithmetic
using OptiFloat
using OptiFloat: all_subexpressions, local_error, evaluate_exact, evaluate, accuracy


T = Float16
x = T(5.13e3)
point = (;x=x)

expr = :(x + 1 - x)
evaluate_exact(expr, point)

d = Dict(e => local_error(e,point) for e in all_subexpressions(expr))
target = Dict(
    1              => 0,
    :(x + 1)       => 1.0,
    :((x + 1) - x) => 1.0,
    :x             => 0,
)
@assert d == target


T = Float16
x = T(5.1319e4)
x = T(0.1)
point = (;x=x)
expr = :((1 / (x+1) - (2/x)) + 1/(x+1))
g(x) = 2/(x^3-x)
evaluate_exact(expr, point)
evaluate(expr, point)
accuracy(expr, point)
#expr = :(1 / (x+1) - (2/x))
d = Dict(e => local_error(e,point) for e in all_subexpressions(expr))

#########################################################################

using Plots

f(x) = x+1-x
start = Float16(1e4)
step = start*Float16(0.1)
p1 = plot(f, -start:step:start)
plot(p1, x -> evaluate_exact(f,x), -start:step:start)



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

# function sample(x::Interval{T}, batchsize::Int) where T
#     # TODO: sample random bits in the interval in stead of uniform dist
#     # TODO: make sure we can sample from (-Inf,Inf)
#     (a,b) = bounds(x)
#     rand(T, batchsize) .* (b-a) .+ a
# end
# function sample(x::Dict{Symbol,<:Interval}, batchsize::Int)
#     dict = Dict(k=>sample(i,batchsize) for (k,i) in x)
#     (zip(keys(x), p) for p in zip(values(dict)...))
# end
# function local_error(expr, intervals, batchsize=100)
#     points = sample(intervals, batchsize)
#     map(points) do point
#         local_error(expr, point...)
#     end
# end
