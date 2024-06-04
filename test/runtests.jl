using Test
using OptiFloat
using OptiFloat: frombits, sample_bitpattern


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
