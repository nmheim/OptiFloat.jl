using Metatheory
using DynamicExpressions
using OptiFloat: recursive_rewrite, REWRITE_THEORY, rewrite_once

theory = @theory a b c d begin
    a/b - c/d --> (a*d - b*c) / (b*d)
    a/b + c/d --> (a*d + b*c) / (b*d)
end

@testset "rewrite_once" begin
    # julia expression
    expr = :(1/x - y/z)
    rewritten_expr = :((1z - (x*y))/(x*z))
    rws = rewrite_once(expr, theory)
    display(rws)
    @test all(rws .== [expr, rewritten_expr])

    # dynamic expression
    dexpr = parse_expression(expr,
        binary_operators = [-, /],
        variable_names = ["x", "y", "z"],
    )
    rewritten_dexpr = parse_expression(rewritten_expr,
        binary_operators = [-, /, *],
        variable_names = ["x", "y", "z"],
    )
    display("asdfasdfasdf")
    rws = rewrite_once(dexpr.tree, theory)
    #display([dexpr.tree, rewritten_dexpr.tree])
    #error()
    @test all(rws .== [dexpr.tree, rewritten_dexpr.tree])
end

@testset "recursive_rewrite" begin
    expr = :((a/b - c/d) + 1/f)
    rws = [
     expr
     :((a * d - b * c) / (b * d) + 1 / f)
     :(((a * d - b * c) * f + (b * d) * 1) / ((b * d) * f))
    ]

    for (target, result) in zip(rws, recursive_rewrite(expr, theory))
        @test target == result
    end
end
