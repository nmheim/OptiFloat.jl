using DynamicExpressions

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


expr = :((1/(x-1) - 2/x) + (1/(x+1)))
expr = :((1/(x-1) - 2/x) + (1/(x+1)) + cos(x))
expr = :(x+1)

unary, binary = unary_binary_ops(expr)
operators = OperatorEnum(; binary_operators=binary, unary_operators=unary)
x1 = Node{T}(feature=1)
expression = lambdify(expr, :x)(x1)
X  = reshape(xs, 1, :)
expression(X, operators)

