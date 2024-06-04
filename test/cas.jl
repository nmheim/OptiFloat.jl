using Metatheory
using TermInterface
using Metatheory.Library

mult_t = @commutative_monoid (*) 1
plus_t = @commutative_monoid (+) 0

minus_t = @theory a b begin
  # TODO Jacques Carette's post in zulip chat
  a - a --> 0
  a - b --> a + (-1 * b)
  -a --> -1 * a
  a + (-b) --> a + (-1 * b)
end

mulplus_t = @theory a b c begin
    # TODO FIXME these rules improves performance and avoids commutative
    # explosion of the egraph
    a + a --> 2 * a
    0 * a --> 0
    a * 0 --> 0
    a * (b + c) == ((a * b) + (a * c))
    a + (b * a) --> ((b + 1) * a)
end
  
pow_t = @theory x y z n m p q begin
    (y^n) * y --> y^(n + 1)
    x^n * x^m == x^(n + m)
    (x * y)^z == x^z * y^z
    (x^p)^q == x^(p * q)
    x^0 --> 1
    0^x --> 0
    1^x --> 1
    x^1 --> x
    x * x --> x^2
    inv(x) == x^(-1)
end
  
div_t = @theory x y z begin
    x / 1 --> x
    # x / x => 1 TODO SIGN ANALYSIS
    x / (x / y) --> y
    x * (y / x) --> y
    x * (y / z) == (x * y) / z
    x^(-1) == 1 / x
end
  
trig_t = @theory θ begin
    sin(θ)^2 + cos(θ)^2 --> 1
    sin(θ)^2 - 1 --> cos(θ)^2
    cos(θ)^2 - 1 --> sin(θ)^2
    tan(θ)^2 - sec(θ)^2 --> 1
    tan(θ)^2 + 1 --> sec(θ)^2
    sec(θ)^2 - 1 --> tan(θ)^2
    cot(θ)^2 - csc(θ)^2 --> 1
    cot(θ)^2 + 1 --> csc(θ)^2
    csc(θ)^2 - 1 --> cot(θ)^2
end
  
# Dynamic rules
fold_t = @theory a b begin
    -(a::Number) => -a
    a::Number + b::Number => a + b
    a::Number - b::Number => a - b
    a::Number * b::Number => a * b
    a::Number^b::Number => begin
      b < 0 && a isa Int && (a = float(a))
      a^b
    end
    a::Number / b::Number => a / b
end
  

theory = union(plus_t, minus_t, mult_t, mulplus_t, pow_t, div_t, trig_t, fold_t)

function to_exprs(g::EGraph, n::VecExpr)
    v_isexpr(n) || return [get_constant(g, v_head(n))]

    h = get_constant(g, v_head(n))
    argss = map(v_children(n)) do child
        to_exprs(g,child)
    end
    argss = Iterators.product(argss...) |> collect |> vec
    map(argss) do args
        args = [a for a in args]
        if v_iscall(n)
          maketerm(Expr, :call, [h; args])
        else
          maketerm(Expr, h, args)
        end
    end
end

function to_exprs(g::EGraph, eclass_id)
    mapreduce(
        node -> to_exprs(g,node),
        vcat,
        g.classes[Metatheory.EGraphs.IdKey(eclass_id)]
    )
end


expr = :(a - b * c)
g = EGraph(expr)

union!(g, addexpr!(g,:a), addexpr!(g,:b))
saturate!(g, theory)

r = find(g, g.root)

to_exprs(g,r)
