using DynamicExpressions: Node, parse_expression
using OptiFloat: Candidate, Regimes, evaluate_approx, evaluate_exact

@testset "Evaluate (exact)" begin
    # expression evaluation
    T = Float16
    expr = :(x + 1 - y)
    dexpr = parse_expression(
        expr; binary_operators=[+, -], variable_names=["x", "y"], node_type=Node{T}
    )
    x = T(5e3)
    xs = reshape([x, x], 2, 1)
    @test evaluate_approx(dexpr, xs) == T[0]
    @test evaluate_approx(dexpr.tree, dexpr.metadata.operators, xs) == T[0]
    @test evaluate_approx(dexpr, [x, x]) == T(0)
    @test evaluate_approx(dexpr.tree, dexpr.metadata.operators, [x, x]) == T(0)

    @test evaluate_exact(dexpr, xs) == T[1]
    @test evaluate_exact(dexpr.tree, dexpr.metadata.operators, xs) == T[1]
    @test evaluate_exact(dexpr, [x, x]) == T(1)
    @test evaluate_exact(dexpr.tree, dexpr.metadata.operators, [x, x]) == T(1)
end

# @testset "Evaluate regimes" begin
#     T = Float64
#     kws = (;
#         binary_operators=[+, -, ^, *, /],
#         unary_operators=[-, sqrt],
#         variable_names=["x"],
#         node_type=Node{T},
#     )
#     e1 = parse_expression(:(1.0 / ((-1.0 * x) + sqrt((x^2.0) - 1.0))); kws...)
#     e2 = parse_expression(:((-1.0 * x) - sqrt((x^2.0) - 1.0)); kws...)
#     xs = reshape(T[-100, 1, 100], 1, :)
#     c1 = Candidate(e1,e1,xs)
#     c2 = Candidate(e2,e2,xs)
#     regs = Regimes((c1, T(-Inf), T(-1.0)), (c2, T(-1.0), T(Inf)))
#     res = evaluate_exact(regs, xs)
#     res2 = vcat(evaluate_exact(e1, xs[:, 1:1]), evaluate_exact(e2, xs[:, 2:3]))
#     @test all(res .== res2)
# 
#     #FIXME: reintroduce
#     #@test biterror(regs, e1, xs) == 0
#     #@test biterror(e1, e1, xs) > 0
#     #@test biterror(e2, e1, xs) > 0
# end
