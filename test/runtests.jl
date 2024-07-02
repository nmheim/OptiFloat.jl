using Test
using OptiFloat
using OptiFloat: frombits, sample_bitpattern, evaluate_exact, all_subexpressions, accuracy,
    ulpdistance, biterror, local_biterror, Regimes
using DynamicExpressions: OperatorEnum, Node


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


@testset "Biterror" begin
    @test ulpdistance(Float16(0), Float16(1)) == 15360

    T = Float16
    x = T(5e3)
    f(x) = x+1-x
    # first 14 significant bits should be incorrect
    @assert round(Int, biterror(f, x)) == 14

    a = Node{T}(feature=1)
    ops = OperatorEnum(binary_operators=[+,-])
    expr = a + 1 - a
    X = reshape([x], 1, 1)
    @test round(Int, only(biterror(expr, ops, X))) == 14
end

@testset "Evaluate regimes" begin
    T = Float64
    x1 = Node{T}(feature=1)
    ops = OperatorEnum(binary_operators=[+,-,^,*,/], unary_operators=[-,sqrt])
    e1 =  1.0 / ((-1.0 * x1) + sqrt((x1 ^ 2.0) - 1.0))
    e2 = (-1.0 * x1) - sqrt((x1 ^ 2.0) - 1.0)

    regs = Regimes((e1,-Inf,-1.0), (e2,-1.0,Inf))

    xs = reshape(T[-100, 1, 100], 1, :)
    res = evaluate_exact(regs, ops, xs)
    res2 = vcat(evaluate_exact(e1, ops, xs[:,1:1]), evaluate_exact(e2, ops, xs[:,2:3]))
    @test all(res .== res2)

    @test biterror(regs, e1, ops, xs) == 0
    @test biterror(e1, e1, ops, xs) > 0
    @test biterror(e2, e1, ops, xs) > 0
end

@testset "Accuracy" begin
   T = Float16
   x = T(5.13e3)
   f(x,y) = x + 1 - y
   @test accuracy(f, x, x) == 0
end

@testset "Local biterror dynamic expression" begin
    operators = OperatorEnum(; binary_operators=[+, -])
    T = Float16
    a = Node{T}(feature=1)
    expression = a + 1 - a
    x = reshape(T[5e3 for _ in 1:100], 1, 100)
    e = local_biterror(expression, operators, x)
    @test e ≈ T(log2(ulpdistance(T(0), T(1))))

    d = Dict(e => local_biterror(e,operators,x) for e in all_subexpressions(expression))
    @test d isa Dict{Node{T},T}

    target = Dict(
        Node{T}(val=1.0) => 0,
        a+1 => 0,
        (a + 1) - a => T(log2(ulpdistance(T(0), T(1)))),
        a => 0
    )
    @test target==d
end
