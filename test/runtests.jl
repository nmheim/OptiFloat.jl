using Test
using OptiFloat
using OptiFloat: frombits, sample_bitpattern, evaluate_exact, all_subexpressions,
    ulpdistance, biterror, local_biterror, local_biterrors, Regimes, evaluate_approx
using DynamicExpressions: OperatorEnum, Node, parse_expression


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

@testset "Evaluate (exact)" begin
    # expression evaluation
    T = Float16
    expr = :(x + 1 - y)
    dexpr = parse_expression(expr, binary_operators=[+,-], variable_names=["x", "y"], node_type=Node{T})
    x = T(5e3)
    xs = reshape([x, x], 2, 1)
    @test evaluate_approx(dexpr, xs) == T[0]
    @test evaluate_approx(dexpr.tree, dexpr.metadata.operators, xs) == T[0]
    @test evaluate_approx(dexpr, [x,x]) == T(0)
    @test evaluate_approx(dexpr.tree, dexpr.metadata.operators, [x,x]) == T(0)

    @test evaluate_exact(dexpr, xs) == T[1]
    @test evaluate_exact(dexpr.tree, dexpr.metadata.operators, xs) == T[1]
    @test evaluate_exact(dexpr, [x,x]) == T(1)
    @test evaluate_exact(dexpr.tree, dexpr.metadata.operators, [x,x]) == T(1)
end


@testset "Evaluate regimes" begin
    T = Float64
    kws = (; binary_operators=[+,-,^,*,/], unary_operators=[-,sqrt], variable_names=["x"], node_type=Node{T})
    e1 = parse_expression(:(1.0 / ((-1.0 * x) + sqrt((x ^ 2.0) - 1.0))); kws...)
    e2 = parse_expression(:((-1.0 * x) - sqrt((x ^ 2.0) - 1.0)); kws...)

    regs = Regimes((e1,T(-Inf),T(-1.0)), (e2,T(-1.0),T(Inf)))
    xs = reshape(T[-100, 1, 100], 1, :)
    res = evaluate_exact(regs, xs)
    res2 = vcat(evaluate_exact(e1, xs[:,1:1]), evaluate_exact(e2, xs[:,2:3]))
    @test all(res .== res2)

    #FIXME: reintroduce
    #@test biterror(regs, e1, xs) == 0
    #@test biterror(e1, e1, xs) > 0
    #@test biterror(e2, e1, xs) > 0
end




@testset "Biterror" begin
    @test ulpdistance(Float16(0), Float16(1)) == 15360

    T = Float16
    dexpr = parse_expression(:(x+1-x), binary_operators=[+,-], variable_names=["x"], node_type=Node{T})

    x = T(5e3)
    # first 14 significant bits should be incorrect
    @test round(Int, biterror(dexpr, [x])) == 14
    @test round.(Int, biterror(dexpr, reshape([x],1,1), accum=identity)) == [14]
end

@testset "Local biterror dynamic expression" begin

    T = Float16
    kws = (; binary_operators=[+,-], variable_names=["x1"], node_type=Node{T})
    dexpr = parse_expression(:(x1+1-x1); kws...)

    x = reshape(T[5e3 for _ in 1:100], 1, 100)
    e = local_biterror(dexpr, x)
    @test e ≈ T(log2(ulpdistance(T(0), T(1))))

    d = local_biterrors(dexpr, x)
    @test d isa Dict{Node{T},T}

    a = Node(T, feature=1)
    target = Dict(
        Node{T}(val=1.0) => 0,
        a+1 => 0,
        (a + 1) - a => T(log2(ulpdistance(T(0), T(1)))),
        a => 0
    )
    @test target==d
end
