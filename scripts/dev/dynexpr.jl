using DynamicExpressions
using OptiFloat


using Metatheory

e = :(x + 1 - x)
e = :(x * x + x - 1)
#e = :((1 + x * x * x) * 2 - 2)

ex = parse_expression(
    e;
    variable_names=["x"],
    binary_operators=[-, +, *],
    node_type=Node{Float16},
)


g = EGraph(ex.tree)
g = EGraph(e)
saturate!(g, OptiFloat.SIMPLIFY_THEORY)
extract!(g, astsize)
