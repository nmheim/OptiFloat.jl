using Metatheory
using DynamicExpressions
using OptiFloat: recursive_rewrite, REWRITE_THEORY, rewrite_once, simplify, alternatives


@testset "rewrite_once" begin
    theory = @theory a b c d begin
        a/b - c/d --> (a*d - b*c) / (b*d)
        a/b + c/d --> (a*d + b*c) / (b*d)
    end

    # julia expression
    expr = :(1/x - y/z)
    rewritten_expr = :((1z - (x*y))/(x*z))
    rws = rewrite_once(expr, theory)
    @test all(rws .== [expr, rewritten_expr])

    # dynamic expression
    # FIXME: enable!
    # kws = (; binary_operators = [-, /, *], variable_names = ["x", "y", "z"])
    # dexpr = parse_expression(expr; kws...)
    # rewritten_dexpr = parse_expression(rewritten_expr; kws...)
    # rws = rewrite_once(dexpr, theory)
    # @test all(rws .== [dexpr, rewritten_dexpr])
end

@testset "recursive_rewrite" begin
    theory = @theory a b c d begin
        a/b - c/d --> (a*d - b*c) / (b*d)
        a/b + c/d --> (a*d + b*c) / (b*d)
    end

    expr = :((a/b - c/d) + 1/f)

    expr = :((a/b - c/d) + 1/f)
    rws = [
     expr
     :((a * d - b * c) / (b * d) + 1 / f)
     :(((a * d - b * c) * f + (b * d) * 1) / ((b * d) * f))
    ]

    for (target, result) in zip(rws, recursive_rewrite(expr, theory))
        @test target == result
    end

    # FIXME: enable!
    # kws = (; binary_operators = [+, -, /, *], variable_names = ["a", "b", "c", "d", "f"])
    # dexpr = parse_expression(expr; kws...)
    # drws = [parse_expression(e; kws...) for e in rws]
    # for (target, result) in zip(drws, recursive_rewrite(dexpr, theory))
    #     @test target == result
    # end
end

#@testset "alternatives" begin
    theory = @theory a b begin
        a - b --> (a^2 - b^2) / (a + b)
    end

    original = :((x - sqrt(x^2 - 4y)) / (2y))
    alts = recursive_rewrite(original; depth=2)
    cnds = mapreduce(alternatives, vcat, alts)
#end

