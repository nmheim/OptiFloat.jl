using OptiFloat: recursive_rewrite, REWRITE_THEORY, rewrite_once
using Metatheory

theory = @theory a b c d begin
    a/b - c/d --> (a*d - b*c) / (b*d)
    a/b + c/d --> (a*d + b*c) / (b*d)
end

@testset "rewrite_once" begin
    expr = :(1/x - y/z)
    rws = rewrite_once(expr, theory)
    @test all(rws .== [expr, :((1z - (x*y))/(x*z))])
end

@testset "recursive_rewrite" begin
    expr = :((a/b - c/d) + e/f)
    rws = [
     expr
     :((a * d - b * c) / (b * d) + e / f)
     :(((a * d - b * c) * f + (b * d) * e) / ((b * d) * f))
    ]


    for (target, result) in zip(rws, recursive_rewrite(expr, theory))
        @test target == result
    end
end
