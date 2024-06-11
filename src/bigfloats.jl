function numbits(a::BigFloat)
    n = a.prec
    for i=1:(a.prec>>count_ones(sizeof(Base.GMP.Limb)*8-1))
        tz = trailing_zeros(unsafe_load(a.d,i))
        n -= tz
        if tz < sizeof(Base.GMP.Limb)*8
            break
        end
    end
    return n
end

function mantissarep(a::BigFloat)
    mantissa = BigInt(a*BigFloat(2)^(numbits(a)-a.exp))
    (mantissa, a.exp)
end

function tobigint(x::BigFloat)
    (sig, exp, sign) = Base.decompose(x)
    y = BigInt(exp + x.prec) << sig.size | sig
    sign * y
end


function _bitstring(x::BigFloat)
    (sig, exp, sign) = Base.decompose(x)
    (sign==1 ? "0" : "1") * bitstring(exp) * string(sig,base=2,pad=sig.size)
end
