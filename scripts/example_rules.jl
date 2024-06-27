using Metatheory
using Metatheory.Library

function simplify(expr, theory; steps=1)
    @info "simplify" expr
    for _ in 1:steps
        g = EGraph(expr)
        #p = SaturationParams(
        #    timeout = 12,
        #    scheduler = Schedulers.BackoffScheduler,
        #    schedulerparams = (6000, 5),
        #    timer = false,
        #)
        #saturate!(g, theory, p)
        saturate!(g, theory)
        expr = extract!(g, astsize)
    end
    expr
end


REWRITE_THEORY = @theory a x y z begin
    -x --> 0 - x
    #0 - x --> -x
    x+y --> (x^2-y^2) / (x-y)
    x-y --> (x^2-y^2) / (x+y)
    (x-y)+z --> x-(y-z) 
    x-(y-z) --> (x-y)+z
end

SIMPLIFY_THEORY = @theory a x y z begin
    -x == 0 - x
    x+y --> (x^2-y^2) / (x-y)
    (x-y)+z == x-(y-z) 

    sqrt(x)^2 --> x
    (-x)^2 --> x^2

    x - x --> 0
    0 + x --> x

    x / y / z --> x / (y * z)
    (a*x) / (a*y) --> x/y
end
SIMPLIFY_THEORY = SIMPLIFY_THEORY ∪ @commutative_monoid (*) 1
