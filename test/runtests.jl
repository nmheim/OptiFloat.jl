using IntervalArithmetic
using OptiFloat

f(x,y)= x^y / (x^y + 2)

args = Float16.((3.0,1.1))
args = Float16.((-1.1, 7.0))

input_precision = 4
args = BigFloat.((big"-1.1", big"7.0"), precision=input_precision)

acc_res = accurate_result(f, args...)
res = setprecision(input_precision) do
    f(args...)
end
accuracy(f, args...)
