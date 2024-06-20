module OptiFloat

const Point{syms,N,T} = NamedTuple{syms, <:NTuple{N,T}} where {syms,N,T<:Real}
const Batch{syms,N,T} = NamedTuple{syms, <:NTuple{N,Vector{T}}} where {syms,N,T<:Real}

include("sample.jl")
include("evaluate.jl")
include("oracle.jl")

function rewrite_once(expr, theory)
    rws = Expr[]
    for rule in theory
        rw = rule(expr)
        if !isnothing(rw)
            push!(rws, rw)
        end
    end
    rws
end

end # module OptiFloat
