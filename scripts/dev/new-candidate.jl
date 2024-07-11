using DynamicExpressions
using Metatheory
using Metatheory.Rewriters
using OptiFloat

struct CandidateRewriter{F}
    rw::F
end


rule = @rule a b (a-b) --> (a^2-b^2)/(a+b)

original = :((-1x - sqrt(x^2 - 1)) / (log(x)))
original = :(-x - sqrt(x^2 - 1))
original = :(-x - sqrt(x^2))

function (cr::CandidateRewriter)(expr)
    x = cr.rw(expr)
    if isnothing(x)
        expr
    else
        Expr(:meta, :candidate, expr, operation(x), arguments(x)...)
    end
end

cr = CandidateRewriter(rule)
y = cr(original)
y = Postwalk(cr)(original)


candidates(expr, theory) = [expr]
function candidates(expr::Expr, theory)
    if head(expr)==:meta && expr.args[1] == :candidate
        orig = expr.args[2]
        op = expr.args[3]
        args = expr.args[4:end]
        argss = [candidates(arg, theory) for arg in args]
        @info "before" argss
        argss = map(a -> OptiFloat.simplify(a,theory), argss)
        @info "after" argss
        [[orig]; vec([Expr(:call, op, args...) for args in Iterators.product(argss...)])]
    else
        argss = [candidates(arg, theory) for arg in arguments(expr)]
        argss = Iterators.product(argss...)
        [maketerm(typeof(expr), head(expr), [operation(expr); args...], nothing) for args in argss] |> vec
    end
end

#candidates(:(1+1))
candidates(y, OptiFloat.SIMPLIFY_THEORY)
# expr without :meta :candidate
# @test random_expr == candidates(random_expr)
