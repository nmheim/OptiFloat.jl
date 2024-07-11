using DynamicExpressions
using Metatheory
using Metatheory.Rewriters
using OptiFloat
using OptiFloat: simplify

struct CandidateRewriter{F}
    rw::F
end

function (cr::CandidateRewriter)(expr)
    x = cr.rw(expr)
    if isnothing(x)
        expr
    else
        Expr(:candidate, expr, operation(x), arguments(x)...)
    end
end


_candidates(expr, theory) = [expr]
function _candidates(expr::Expr, theory)
    if head(expr)==:candidate
        orig = expr.args[1]
        op = expr.args[2]
        args = expr.args[3:end]
        argss = [_candidates(arg, theory) for arg in args]

        # only simplify children of current node
        argss = map(argss) do args
            map(a -> simplify(a,theory), args)
        end

        [orig; vec([Expr(:call, op, args...) for args in Iterators.product(argss...)])]
    else
        argss = [_candidates(arg, theory) for arg in arguments(expr)]
        argss = Iterators.product(argss...)
        [maketerm(typeof(expr), head(expr), [operation(expr); args...], nothing) for args in argss] |> vec
    end
end
function candidates(expr, theory)
    cs = _candidates(expr, theory)

    # very first element contains original expr with Expr(:meta, :candidate, ...)s.
    # remove it. keep only unique new exprs
    unique(cs[2:end])
end



rule = @rule a b (a-b) --> (a^2-b^2)/(a+b)

original = :((neg(1x) - sqrt(x^2 - 1)) / (log(x)))
#original = :(-x - sqrt(x^2))
#original = :(-x - sqrt(x^2 - 1))
#original = :(neg(x) - sqrt(x^2 - 1))
cr = CandidateRewriter(rule)
y = cr(original)
y = Postwalk(cr)(original)



#candidates(:(1+1))
candidates(y, OptiFloat.SIMPLIFY_THEORY)
# expr without :meta :candidate
# @test random_expr == candidates(random_expr)
