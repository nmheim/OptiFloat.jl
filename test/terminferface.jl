using TermInterface
using Metatheory
using DynamicExpressions: Node, OperatorEnum, parse_expression
using OptiFloat: all_subexpressions

@testset "TermInterface for Expression" begin
    ex = :(a + b)
    NT = Node{Float16}
    kws = (; binary_operators=[-,+], variable_names=["a","b"], node_type=NT)
    meta = (; operators=OperatorEnum(binary_operators=kws.binary_operators), variable_names=kws.variable_names)
    a = Expression(NT(feature=1); meta...)
    b = Expression(NT(feature=2); meta...)
    dex = parse_expression(ex; kws...)
    @test head(dex) == +
    @test children(dex) == [a,b]
    @test operation(dex) == +
    @test arguments(dex) == [a,b]
    @test isexpr(dex)
    @test iscall(dex)
    @test dex == maketerm(Expression, +, [a,b], nothing)
end

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
    vars = ["x"]
    meta = (; variable_names=vars, operators=ops)
    dex = Expression(x1; meta...)

    rule = @rule x x --> x + 1
    @test rule(dex) == Expression(x1+1; meta...)

    rule = @rule x x+1 --> x+2
    @test rule(Expression(x1+1; meta...)) == x1+2
end
