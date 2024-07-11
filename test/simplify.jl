# '((1 . 1)
# (0 . 0)
# ((+ 1 0) . 1)
# ((+ 1 5) . 6)
# ((+ x 0) . x)
# ((- x 0) . x)
# ((* x 1) . x)
# ((/ x 1) . x)
# ((- (* 1 x) (* (+ x 1) 1)) . -1)
# ((- (+ x 1) x) . 1)
# ((- (+ x 1) 1) . x)
# ((/ (* x 3) x) . 3)
# ((- (* (sqrt (+ x 1)) (sqrt (+ x 1))) (* (sqrt x) (sqrt x))) . 1)
# ((+ 1/5 3/10) . 1/2)
# ((cos (PI)) . -1)
# ((pow (E) 1) . (E))
# ;; this test is problematic and runs out of nodes currently
# ;;((/ 1 (- (/ (+ 1 (sqrt 5)) 2) (/ (- 1 (sqrt 5)) 2))) . (/ 1 (sqrt 5)))

using Metatheory
using OptiFloat: simplify, SIMPLIFY_THEORY
using Test

@testset "simplify" begin
    cases = [
        (1, 1)
        (0, 0)
        (:(1 + 0), 1)
        # (:(1 + 5), 6) include => rules
        (:(x - 0), :x)
        (:(x * 1), :x)
        (:(x / 1), :x)
        (:((1 * x) - ((x + 1) * 1)), -1)
        (:((x + 1) - x), 1)
        (:((x + 1) - 1), :x)
        (:((x * 3) / x), 3)
        (:(((sqrt(x + 1)) * (sqrt(x + 1))) - (sqrt(x) * sqrt(x))), 1)
        #((+ 1/5 3/10) . 1/2)
    ]
    for (expr, target) in cases
        @test simplify(expr, SIMPLIFY_THEORY) == target
    end
end
