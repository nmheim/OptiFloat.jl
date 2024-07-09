using OptiFloat: frombits, sample_bitpattern, logsample

splitafter(vec, idx) = vec[1:idx], vec[(idx + 1):end]
FLOATS = [Float16, Float32, Float64]

@testset "Sample float bitpatterns" begin
    for T in FLOATS
        for x in rand((-maxintfloat(T)):maxintfloat(T), 20)
            b = bitstring(x)
            (n_sign, n_expo, _) = OptiFloat._bits(T)
            sign, rest = splitafter(b, n_sign)
            expo, mant = splitafter(rest, n_expo)
            y = frombits(T, sign, expo, mant)
            @test x == y
        end
    end

    for T in FLOATS
        @test sample_bitpattern(T) isa T
    end
end

@testset "Sample float logspace" begin
    for T in FLOATS
        xs = logsample(T, 3, 2)
        @test xs isa Matrix{T}
        @test size(xs) == (3, 2)
    end

    xs = logsample(x -> sum(sqrt.(x)), Float16, 2, 10)
    @test size(xs) == (2,10)
    @test all(xs .> 0)
end

