sample_bitpattern(expr::Expression, args...) = sample_bitpattern(expr.tree, expr.metadata.operators, args...)
function sample_bitpattern(expr::Node, ops::OperatorEnum, T::Type, inputsize::Int, batchsize::Int)
    samples = []
    while length(samples)<batchsize
        X = sample_bitpattern(T, inputsize, 1)
        try
            y = evaluate_exact(expr, ops, X) |> only
            if isfinite(y)
                push!(samples, X)
            end
        catch e
            if e isa DomainError
                continue
            else
                rethrow(e)
            end
        end
    end
    reduce(hcat, samples)
end
sample_bitpattern(T::Type, shape::Int...) = reshape(T[sample_bitpattern(T) for _ in 1:prod(shape)], shape...)
function sample_bitpattern(T::Type{<:AbstractFloat})
    n_sign, n_expo, n_mant = _bits(T)
    _sample(n::Int) = rand(['0','1'], n)

    # prevent nans/infs
    expo = _sample(n_expo)
    while all(expo .== '1')
        expo = _sample(n_expo)
    end

    sign = _sample(n_sign)
    mant = _sample(n_mant)
    frombits(T, sign, expo, mant)
end
function sample_bitpattern(T::Type, low, high, shape::Int...)
    res = if low==high
        [T(low) for _ in 1:prod(shape)]
    else
        xs = T[]
        while length(xs) < prod(shape)
            x = sample_bitpattern(T)
            if low < x < high
                push!(xs,x)
            end
        end
        xs
    end
    reshape(res, shape...)
end

function frombits(T::Type{<:AbstractFloat}, sign, exponent, mantissa)::T
    n_sign, n_expo, n_mant = _bits(T)
    @assert length(sign)==n_sign "$T must have $n_sign sign bit. Found: $(length(sign))"
    @assert length(exponent)==n_expo "$T must have $n_expo exponent bits. Found: $(length(exponent))"
    @assert length(mantissa)==n_mant "$T must have $n_mant mantissa bits. Found: $(length(mantissa))"
    f = String(vcat(sign, exponent, mantissa))
    reinterpret(T, Meta.parse(string("0b", f)))
end
function frombits(T::Type{<:AbstractFloat}, sign::S, exponent::S, mantissa::S)::T where {S<:String}
    frombits(T, collect(sign), collect(exponent), collect(mantissa))
end

_bits(::Type{Float16}) = (sign=1, exponent=5, mantissa=10)
_bits(::Type{Float32}) = (sign=1, exponent=8, mantissa=23)
_bits(::Type{Float64}) = (sign=1, exponent=11, mantissa=52)
