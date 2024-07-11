using TermInterface
using DynamicExpressions.NodeModule: node_factory, default_allocator
using DynamicExpressions.ExpressionModule: Metadata


## TermInterface.jl for Node

function _get_feature(s::Symbol)
    s = string(s)
    x, f = s[1], s[2:end]
    @assert x == 'x'
    parse(Int, f)
end

TermInterface.isexpr(n::Node) = n.degree > 0
TermInterface.iscall(n::Node) = isexpr(n)

# expression
function TermInterface.maketerm(N::Type{<:Node{T}}, head::UInt8, children, metadata) where {T}
    if length(children) == 2
        (left, right) = children
    elseif length(children) == 1
        (left,) = children
        right = nothing
    else
        error("whwaaaaaaa")
    end
    node_factory(N, T, nothing, nothing, head, left, right, default_allocator)
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
    n.degree == 1 ? [n.op, n.l] : [n.op, n.l, n.r]
end
function TermInterface.operation(n::Node)
    iscall(n) ? n.op : error("operation called on a non-function call expression")
end
function TermInterface.arguments(n::Node)
    iscall(n) ? children(n)[2:end] : error("arguments called on a non-function call expression")
end


## TermInterface.jl for Expression


TermInterface.isexpr(e::Expression) = isexpr(e.tree)
TermInterface.iscall(e::Expression) = iscall(e.tree)
TermInterface.arity(e::Expression) = convert(Int, e.tree.degree)
TermInterface.operation(e::Expression) = head(e)
TermInterface.arguments(e::Expression) = children(e)

function TermInterface.head(e::Expression)
    if isexpr(e)
        opcode = e.tree.op
        if arity(e) == 1
            e.metadata.operators.unaops[opcode]
        else
            e.metadata.operators.binops[opcode]
        end
    else
        error("'$e' does not have a head.")
    end
end

function TermInterface.children(e::Expression)
    if isexpr(e)
        if arity(e) == 1
            [Expression(e.tree.l, e.metadata),]
        else
            [Expression(e.tree.l, e.metadata), Expression(e.tree.r, e.metadata)]
        end
    else
        error("'$e' does not have children.")
    end
end

# FIXME: getting vectors of any from MT.jl, can we change that?
function TermInterface.maketerm(::Type{<:Expression}, head, children::Vector, metadata)
    cs = [isa(c,Expression) ? c.tree : c for c in children]
    Expression(head(cs...), metadata)
end
function TermInterface.maketerm(::Type{<:Expression}, head, children::Vector{<:Node}, metadata)
    Expression(head(children...); metadata...)
end
function TermInterface.maketerm(::Type{<:Expression}, head, children::Vector{<:Node}, metadata::Metadata)
    Expression(head(children...), metadata)
end
function TermInterface.maketerm(::Type{<:Expression}, head, children::Vector{<:Expression}, metadata)
    maketerm(Expression, head, [c.tree for c in children], metadata)
end
function TermInterface.maketerm(::Type{<:Expression}, head, children::Vector{<:Expression}, ::Nothing)
    if length(children) == 1
        (left,) = children
        Expression(head(left.tree), left.metadata)
    elseif length(children) == 2
        (left, right) = children
        @assert left.metadata == right.metadata
        Expression(head(left.tree, right.tree), left.metadata)
    else
        error("Expressions can only have one or two children.")
    end
end

# FIXME: make sure MT.jl rules work on dynamic expressions
using Metatheory
using Metatheory.Rules: instantiate
function Metatheory.Rules.instantiate(left::Expression, pat::PatExpr, bindings)
    ntail = map(arg -> instantiate(left, arg, bindings), arguments(pat))
    maketerm(Expression, head(pat), ntail, left.metadata)
end
function Metatheory.Rules.instantiate(left::Expression, pat::PatLiteral, bindings)
    NT = typeof(left.tree)
    Expression(NT(val=pat.value), left.metadata)
end

#function Metatheory.Rules.instantiate(left::Node, pat::PatExpr, bindings)
#    ntail = tuple(map(arg -> instantiate(left, arg, bindings), arguments(pat))...)
#    op = operation(pat)
#    h = DynamicExpressions.OperatorEnumConstructionModule.LATEST_BINARY_OPERATOR_MAPPING[op]
#    @info "make" maketerm(typeof(left), h, ntail, nothing) ntail
#    maketerm(typeof(left), h, ntail, nothing)
#end
#function Metatheory.Rules.instantiate(left::Node, pat::PatLiteral, bindings)
#    typeof(left)(val=pat.value)
#end
