using BenchmarkTools
using DynamicExpressions
using OptiFloat: all_subexpressions, local_biterror, evaluate_exact, accuracy,
    sample_bitpattern, ulpdistance, biterror, lambdify

include("plots.jl")

f(a,b,c) = (-b - sqrt(b^2 - 4*a*c)) / (2*a)

expr = :((-b - sqrt(b^2 - 4*a*c)) / (2*a))

# y = accuracy(f, -1.0, 1.0, 1.0)
@code_warntype evaluate_exact(f, -1.0, 1.0, 1.0)
@btime evaluate_exact(f, -1.0, 1.0, 1.0)

point = (; a=-1.0, b=1.0, c=1.0)
@code_warntype lambdify(expr, keys(point)...)(values(point)...)
@btime lambdify(expr, keys(point)...)(values(point)...)
@btime evaluate_exact(expr, point)

_symbols(e::Expr) = filter(x -> x isa Symbol, all_subexpressions(e))

function unary_binary_ops(expr)
    ops = eval.(unique(operation.(filter(iscall, all_subexpressions(expr)))))
    unary = []
    binary = []
    for op in ops
        nargs = maximum([m.nargs-1 for m in methods(op)])
        if nargs > 1
            push!(binary, op)
        else
            push!(unary, op)
        end
    end
    (unary, binary)
end

function _dynexpr(T::Type{<:Number}, expr::Expr)
    syms = _symbols(expr)
    nodes = [:($s = Node{$T}(feature=$i)) for (i,s) in enumerate(syms)]
    unary, binary = unary_binary_ops(expr)
    quote
        $(nodes...)
        operators = OperatorEnum(; binary_operators=$binary, unary_operators=$unary)
        $expr, operators, $syms
    end
end

macro dynexpr(T, expr)
    :($(_dynexpr(eval(T), expr)))
end

function OptiFloat.local_biterror(expr::Node, X::Matrix; accum=mean) where {syms,N,T}
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

Base.isfinite(x::Interval) = isbounded(x)

dexpr, ops, syms = @dynexpr Interval{BigFloat} (b - sqrt(b^2 - 4*a*c)) / (2*a)
T = Interval{BigFloat}
expr = (b - sqrt(b^2 - 4*a*c)) / (2*a)
X = reshape(T[1.0, -1.0, 1.0], 3, 1)
dexpr(X, ops)

X = reshape(Float16[1.0, -1.0, 1.0], 3, 1)
evaluate_exact(dexpr, ops, X)

operators = OperatorEnum(; binary_operators=[+, -, *, ^, /], unary_operators=[sqrt])
a = Node{T}(feature=1)
b = Node{T}(feature=2)
c = Node{T}(feature=3)
expression = (b - sqrt(b^2 - 4*a*c)) / (2*a)
x = -ones(T, 1, 100)
y = ones(T, 1, 100)
z = ones(T, 1, 100)
X = cat(x,y,z,dims=1)
expression(X, operators)
@btime expression($X, $operators)

@code_warntype evaluate_exact(expr, point)
@code_warntype biterror(f, -1.0, 1.0, 1.0)
@code_warntype biterror.(f, -ones(2), ones(2), ones(2))

@code_warntype biterror(expr)

T = Float64
batchsize = 100

as = sort(sample_bitpattern(T, 300))
ys = map(as) do a
    batch = (;
        a = sample_bitpattern(T, batchsize),
        b = T[a for _ in 1:batchsize],
        c = sample_bitpattern(T, batchsize),
    )
    errorscore.(f, values(batch)...)
    #median(filter(isfinite, accs))
end

plot_accuracy(as, ys)
