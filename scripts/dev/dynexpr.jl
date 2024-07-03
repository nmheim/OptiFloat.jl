using DynamicExpressions
using OptiFloat

e = :((-b - sqrt(b - 4c)) / (2c))

ex = parse_expression(
    e,
    variable_names = ["c", "b"],
    binary_operators = [-, /, *],
    unary_operators = [-, sqrt],
    node_type=Node{Float16}
)

e2 = parse_expression(e, Node{Float16})


candidate = :(2 / (b + sqrt((b ^ 2.0) - (4.0 * c))))
e3 = parse_expression(candidate, Node{Float16})
