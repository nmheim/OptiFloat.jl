using TermInterface
using DynamicExpressions.NodeModule: node_factory, default_allocator

function _get_feature(s::Symbol)
    s = string(s)
    x, f = s[1], s[2:end]
    @assert x == 'x'
    parse(Int, f)
end

TermInterface.isexpr(n::Node) = n.degree > 0
TermInterface.iscall(n::Node) = isexpr(n)

# binary expression
function TermInterface.maketerm(
    N::Type{<:Node{T}}, head::UInt8, children::Tuple{Any,Any}, metadata
) where {T}
    (left, right) = children
    node_factory(N, T, nothing, nothing, head, left, right, default_allocator)
end
# unary expression
function TermInterface.maketerm(
    N::Type{<:Node{T}}, head::UInt8, children::Tuple{Any}, metadata
) where {T}
    (left,) = children
    node_factory(N, T, nothing, nothing, head, left, nothing, default_allocator)
end
# variable
function TermInterface.maketerm(N::Type{<:Node{T}}, head::Symbol, children, metadata) where {T}
    feature = _get_feature(head)
    node_factory(N, T, nothing, feature, nothing, nothing, nothing, default_allocator)
end
# constant
function TermInterface.maketerm(N::Type{<:Node{T}}, head::Number, children, metadata) where {T}
    node_factory(N, T, head, nothing, nothing, nothing, nothing, default_allocator)
end

function TermInterface.head(n::Node)
    if n.constant
        n.val
    else
        if n.degree == 0
            Symbol("x$(n.feature)")
        elseif n.degree == 1 || n.degree == 2
            n.op
        else
            error()
        end
    end
end

function TermInterface.children(n::Node)
    isexpr(n) || error("children called on a non-function call expression")
    n.degree == 1 ? (n.op, n.l) : (n.op, n.l, n.r)
end
function TermInterface.operation(n::Node)
    iscall(n) ? n.op : error("operation called on a non-function call expression")
end
function TermInterface.arguments(n::Node)
    iscall(n) ? children(n)[2:end] : error("arguments called on a non-function call expression")
end



# FIXME: make sure MT.jl rules work on dynamic expressions
# using Metatheory
# using Metatheory.Rules: instantiate
# function Metatheory.Rules.instantiate(left::Node, pat::PatExpr, bindings)
#     @info "instantiate" left pat bindings arguments(pat)
#     ntail = tuple(map(arg -> instantiate(left, arg, bindings), arguments(pat))...)
#     op = operation(pat)
#     h = DynamicExpressions.OperatorEnumConstructionModule.LATEST_BINARY_OPERATOR_MAPPING[op]
#     @info "make" maketerm(typeof(left), h, ntail, nothing) ntail
#     maketerm(typeof(left), h, ntail, nothing)
# end
# 
# function Metatheory.Rules.instantiate(left::Node, pat::PatLiteral, bindings)
#     typeof(left)(val=pat.value)
# end
