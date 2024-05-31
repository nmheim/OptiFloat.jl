using TermInterface
using IntervalArithmetic
using OptiFloat
using OptiFloat: all_subexpressions, local_error

expr = :((1 / (x+1) - (2/x)) + (1/x+1))
#expr = :(1 / (x+1) - (2/x))
x = Float16(1e2)
f(x) = (1/(x-1) - 2/x) + (1/x+1)

# hmm, seems to identify the wrong operation as error prone
# also why is there 1/x in all_subexpressions
Dict(e => local_error(e,(:x,x)) for e in all_subexpressions(expr))

abs(evaluate_exact(f,x) - f(x))



#########################################################################

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
