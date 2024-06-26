using OptiFloat: all_subexpressions, evaluate_exact, accuracy,
    sample_bitpattern, ulpdistance, biterror, lambdify, biterrorscore, local_biterror, @dynexpr


dexpr, ops, syms = @dynexpr Float16 x+1-x
T = Float16
X = reshape(T[5e3 for _ in 1:100], 1, :)
local_biterror(dexpr, ops, X)
d = Dict(e => local_biterror(e,ops,X) for e in all_subexpressions(dexpr))


dexpr, ops, syms = @dynexpr Interval{BigFloat} (b - sqrt(b^2 - 4*a*c)) / (2*a)
#T = Interval{BigFloat}
X = reshape(Float16[1.0, -1.0, 1.0], 3, 1)
evaluate_exact(dexpr, ops, X)

operators = OperatorEnum(; binary_operators=[+, -, *, ^, /], unary_operators=[sqrt])
a = Node{T}(feature=1)
b = Node{T}(feature=2)
c = Node{T}(feature=3)
expression = (b - sqrt(b^2 - 4*a*c)) / (2*a)
expression = a + 1 - a
x = reshape(T[5e3 for _ in 1:100], 1, :)
x = -ones(T, 1, 100) .* 100
y = ones(T, 1, 100)
z = ones(T, 1, 100)
X = cat(x,y,z,dims=1)
expression(X, operators)
@btime expression($X, $operators)
local_biterror(expression, operators, X)
