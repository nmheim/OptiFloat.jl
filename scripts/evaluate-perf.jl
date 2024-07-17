using DynamicExpressions
using OptiFloat: evaluate_exact, evaluate, logsample, evaluate_approx, biterror, ulpdistance
using IntervalArithmetic

begin
    T = Float16
    p = 90
    setprecision(p) do
        x = big"500"
        x = big"5000"
        #x = Float16(100)
        i = interval(x)
        #y = sqrt(i+1) - sqrt(i)
        y = 2 * sqrt(i + 2) - sqrt(i + 1) - sqrt(i)
        y = sqrt(sqrt(sqrt(sqrt(i))))
        y = exp(sqrt(sqrt(i)))
        #y = i + 1
        yf = convert(Interval{T}, y)
        (a, b) = bounds(y)
        (af, bf) = bounds(yf)
        ye = Float16(sqrt(101) - 10)
        @info y a b af bf interval(T(a), T(b)) yf mid(yf) isthin(y) isthin(yf) isthin(
            interval(T(a), T(b))
        ) a == b ulpdistance(T(a), T(b)) ulpdistance(bounds(yf)...) mid(yf) == ye
    end
end

T = Float16
kws = (;
    binary_operators=[-, +, /, ^, *],
    unary_operators=[sqrt, exp, sin],
    node_type=Node{T},
    variable_names=["x"],
)
e1 = parse_expression(:(sqrt(x + 1) - sqrt(x)); kws...)
#e1 = parse_expression(:(sqrt(x)); kws...)
# e1 = parse_expression(:(sqrt(-(sqrt((x ^ 2.0) - 1.0) + x)) * sqrt(-(sqrt((x ^ 2.0) - 1.0) + x))); kws...)
# e1 = parse_expression(:(sqrt(-x) * sqrt(-x)); kws...)
# e1 = parse_expression(:(sqrt(x)); kws...)
e2 = parse_expression(:(1 / (sqrt(x + 1) + sqrt(x))); kws...)
xs = logsample(e1, 1000)

ys = e1(xs; options=EvaluationOptions(; early_exit=false))[1]
ys = e2(xs; options=EvaluationOptions(; early_exit=false))[1]
evaluate_exact(e1, xs; init_precision=53)[1]
e2(xs)
e1(xs)

using BenchmarkTools
@btime evaluate_approx($e1, $xs)
@btime evaluate_exact($e1, $xs; init_precision=53)
@benchmark evaluate_exact($e1, $xs; init_precision=1000)
@btime e1($xs; options=EvaluationOptions(; early_exit=false))
@btime e1($xs)

@profview for _ in 1:1000
    evaluate_approx(e1, xs)
end
@profview for _ in 1:10
    evaluate_exact(e1, xs; init_precision=1000)
end

@btime biterror($e1, $e1, $xs)
