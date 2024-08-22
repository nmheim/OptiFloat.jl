using Test
using OptiFloat

include("terminferface.jl")
include("rewrite.jl")
include("sample.jl")
include("evaluate.jl")
include("error.jl")
include("simplify.jl")
include("infer-regimes.jl")

@testset "@optifloat" begin
    f(x) = sqrt(x + 1) - sqrt(x)
    g = @optifloat sqrt(x + 1) - sqrt(x) T = Float16 batchsize = 100
    @test f(Float16(3730)) == Float16(0.03125)
    @test g(Float16(3730)) == Float16(0.00819)

    f(b, c) = (-b - sqrt(b^2 - 4c)) / (2c)
    g = @optifloat (-b - sqrt(b^2 - 4c)) / (2c) batchsize = 1000 T = Float16
    @test f(Float16(-200), Float16(-0.1)) == Float16(-0.0)
    @test g(Float16(-200), Float16(-0.1)) == Float16(0.004997)
end
