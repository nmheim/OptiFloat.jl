module OptiFloat

using TermInterface: operation, arguments, iscall

const Point{syms,N,T} = NamedTuple{syms, <:NTuple{N,T}} where {syms,N,T<:Real}
const Batch{syms,N,T} = NamedTuple{syms, <:NTuple{N,Vector{T}}} where {syms,N,T<:Real}

include("sample.jl")
include("evaluate.jl")
include("oracle.jl")

rewrite_once(x, theory) = [x]
function rewrite_once(expr::Expr, theory)
    rws = [expr]
    for rule in theory
        rw = try
            rule(expr)
        catch e
            e isa BoundsError ? nothing : rethrow(e)
        end
        if !isnothing(rw)
            push!(rws, rw)
        end
    end
    rws
end

recursive_rewrite(x, theory) = [x]
function recursive_rewrite(expr::Expr, theory)
    if iscall(expr)
        op = operation(expr)
        argss = Iterators.product([recursive_rewrite(a, theory) for a in arguments(expr)]...) |> collect |> vec
        rwo = [rewrite_once(Expr(:call, op, args...), theory) for args in argss]
        @info op expr arguments(expr) argss rwo
        rws = reduce(vcat, rwo)
        rws
    else
        [expr]
    end
end

end # module OptiFloat
