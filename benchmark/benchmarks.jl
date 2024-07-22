using BenchmarkTools
using IntervalArithmetic: Interval, interval
using DynamicExpressions: parse_expression, Node
using OptiFloat: evaluate_approx, evaluate_exact, biterror, logsample
const SUITE = BenchmarkGroup()

T = BigFloat
T = Interval{BigFloat}
(expr, _) = parse_expression(T, :(sqrt(x + 1) - sqrt(x)))
xs = logsample(expr, 10000)

SUITE["evaluate_approx"] = @benchmarkable evaluate_approx($expr, $xs)
SUITE["evaluate_exact"] = @benchmarkable evaluate_exact($expr, $xs)
SUITE["biterror"] = @benchmarkable biterror($expr, $expr, $xs)

@code_warntype evaluate_exact(expr, xs)

@btime expr($Xs)
@btime expr($iXs)

iXs = interval.(Xs)
Xs = BigFloat.(xs)
@profview for _ in 1:10000
    expr(iXs)
end

@profview for _ in 1:100
    evaluate_exact(expr, xs)
end
@profview for _ in 1:10000
    evaluate_approx(expr, xs)
end
