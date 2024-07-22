node_eltype(::Node{T}) where {T} = T
node_eltype(::Expression{T}) where {T} = T

"""
    logsample(expr::Expression, batchsize::Int; eval_exact=true)

Sample valid inputs to `expr`. If `eval_exact=false` `expr` is evaluated with `BigFloat`s
so samples might be generated that cause overflow in the original floating point type of `expr`.
"""
function logsample(expr::Expression, batchsize::Int; eval_exact=true)
    T = node_eltype(expr)
    if eval_exact
        logsample(x -> evaluate_exact(expr, x), T, arity(expr), batchsize)
    else
        logsample(x -> evaluate_approx(expr, x), T, arity(expr), batchsize)
    end
end
function logsample(testfn::Function, T::Type, inputsize::Int, batchsize::Int)
    samplefn(T, n) = rand([-1, 1], n) .* exp.(rand(T, n) .* log(floatmax(T)))
    sample_finite(samplefn, testfn, T, inputsize, batchsize)
end
logsample(T::Type, inputsize::Int, batchsize::Int) = logsample(first, T, inputsize, batchsize)

"""
Generate samples from `samplefn` that yield finite results when called with `testfn`:

```julia
x = samplefn(T, inputsize)
y = testfn(x)  <-- add to samples if isfinite(y)
```
"""
function sample_finite(
    samplefn::Function, testfn::Function, T::Type, inputsize::Int, batchsize::Int
)
    samples = Vector{T}[]
    while length(samples) < batchsize
        x = samplefn(T, inputsize)
        try
            if isfinite(testfn(x))
                push!(samples, x)
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

function sample_bitpattern(expr::Expression, args...)
    sample_bitpattern(expr.tree, expr.metadata.operators, args...)
end
function sample_bitpattern(
    expr::Node, ops::AbstractOperatorEnum, T::Type, inputsize::Int, batchsize::Int
)
    testfn(x) = evaluate_exact(expr, ops, x)
    sample_finite(sample_bitpattern, testfn, T, inputsize, batchsize)
end
function sample_bitpattern(T::Type, shape::Int...)
    reshape(T[sample_bitpattern(T) for _ in 1:prod(shape)], shape...)
end
function sample_bitpattern(T::Type{<:AbstractFloat})
    n_sign, n_expo, n_mant = _bits(T)
    _sample(n::Int) = rand(['0', '1'], n)

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
    res = if low == high
        [T(low) for _ in 1:prod(shape)]
    else
        xs = T[]
        while length(xs) < prod(shape)
            x = sample_bitpattern(T)
            if low < x < high
                push!(xs, x)
            end
        end
        xs
    end
    reshape(res, shape...)
end

function frombits(T::Type{<:AbstractFloat}, sign, exponent, mantissa)::T
    n_sign, n_expo, n_mant = _bits(T)
    @assert length(sign) == n_sign "$T must have $n_sign sign bit. Found: $(length(sign))"
    @assert length(exponent) == n_expo "$T must have $n_expo exponent bits. Found: $(length(exponent))"
    @assert length(mantissa) == n_mant "$T must have $n_mant mantissa bits. Found: $(length(mantissa))"
    f = String(vcat(sign, exponent, mantissa))
    reinterpret(T, Meta.parse(string("0b", f)))
end
function frombits(T::Type{<:AbstractFloat}, sign::S, exponent::S, mantissa::S)::T where {S<:String}
    frombits(T, collect(sign), collect(exponent), collect(mantissa))
end

_bits(::Type{Float16}) = (sign=1, exponent=5, mantissa=10)
_bits(::Type{Float32}) = (sign=1, exponent=8, mantissa=23)
_bits(::Type{Float64}) = (sign=1, exponent=11, mantissa=52)
