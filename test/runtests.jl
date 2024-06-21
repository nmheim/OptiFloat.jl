using Test
using OptiFloat
using OptiFloat: frombits, sample_bitpattern, evaluate_exact, all_subexpressions, local_cost, accuracy, ulpdistance, cost

@testset "Sample float bitpatterns" begin
    splitafter(vec, idx) = vec[1:idx], vec[idx+1:end]
    floats = [Float16, Float32, Float64]

    for T in floats
        for x in rand(-maxintfloat(T):maxintfloat(T), 20)
            b = bitstring(x)
            (n_sign, n_expo, _) = OptiFloat._bits(T)
            sign, rest = splitafter(b, n_sign)
            expo, mant = splitafter(rest, n_expo)
            y = frombits(T, sign, expo, mant)
            @test x==y
        end
    end

    for T in floats
        @test sample_bitpattern(T) isa T
    end
end

@testset "Evaluate exact" begin
    # function evaluation
    f(x) = x+1-x
    x = Float16(5e3)
    @test f(x) == zero(x)
    @test evaluate_exact(f, x) == one(x)

    xs = zeros(Float16, 3) .+ x
    ys = zeros(Float16, 3) .+ x
    g(x,y) = x+1-y
    @test g.(xs,ys) == zero(xs)
    @test evaluate_exact.(g, xs, ys) == zero(xs) .+ 1

    # expression evaluation
    expr = :(x + 1 - y)
    x = Float16(5e3)
    point = (; x=x, y=x)
    @test evaluate_exact(expr, point) == one(x)

    xs = zeros(Float16, 3) .+ x
    ys = zeros(Float16, 3) .+ x
    batch = (; x=xs, y=xs)
    @test evaluate_exact(expr, batch) == zero(xs) .+ 1
end


@testset "Cost" begin
    @test ulpdistance(Float16(0), Float16(1)) == 15360

    T = Float16
    x = T(5e3)
    f(x) = x+1-x
    # first 14 significant bits should be incorrect
    @assert round(Int, cost(f, x)) == 14
end


@testset "Accuracy" begin
   T = Float16
   x = T(5.13e3)
   f(x,y) = x + 1 - y
   @test accuracy(f, x, x) == 0
end

using OptiFloat: @subfunctions, _subfunctions
@testset "subexpressions / subfunctions" begin
    expr = :(x + 1 - y)
    fns = @subfunctions x + 1 - y
    @info fns fns[1](1,2)
    error()
end


@testset "Local cost" begin
    expr = :(x + 1 - y)

    T = Float16
    x = T(5.13e3)
    point = (;x=x, y=x)

    d = Dict(e => local_cost(e,point) for e in all_subexpressions(expr))
    target = Dict(1 => 0, :(x + 1) => 0, :((x + 1) - y) => ulpdistance(T(0), T(1)), :x => 0, :y => 0)
    @test d == target

    batch = (;
        x = zeros(T,3) .+ x,
        y = zeros(T,3) .+ x
    )
    d = Dict(e => local_cost(e,batch) for e in all_subexpressions(expr))
    @test d == target
end
