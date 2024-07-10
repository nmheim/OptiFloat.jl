using TermInterface
using Metatheory
using DynamicExpressions: Node, OperatorEnum, parse_expression
using OptiFloat: all_subexpressions

@testset "all_subexpressions" begin
    kws = (; binary_operators=[+, -], unary_operators=[sqrt], variable_names=["x"])
    for (expr, n) in [(; expr=:(x + 1 - x), length=4), (; expr=:(sqrt(x + 1) - sqrt(x)), length=6)]
        dexpr = parse_expression(expr; kws...)
        @test length(all_subexpressions(expr)) == n
        @test length(all_subexpressions(dexpr.tree)) == n
        @test length(all_subexpressions(dexpr)) == n
        for (tr, ex) in zip(all_subexpressions(dexpr.tree), all_subexpressions(dexpr))
            @test ex.tree == tr
        end
    end
end

 @testset "Rules" begin
    x1 = Node{Float64}(feature=1)
    ops = OperatorEnum(binary_operators=(+,))

    rule = @rule x x --> x + 1
    @test rule(x1) == x1+1

    rule = @rule x x+1 --> x+2
    @test rule(x1+1) == x1+2
 end
