# These rules are auto generated from https://github.com/herbie-fp/herbie/blob/main/src/core/rules.rkt
using Metatheory

theories = (;
    commutativity=(;
        groups=(:arithmetic, :simplify, :fp_safe, :sound),
        rules=[
            @rule "+-commutative" a b (a + b) --> (b + a)
            @rule "*-commutative" a b (a * b) --> (b * a)
        ],
    ),
    associativity=(;
        groups=(:arithmetic, :simplify, :sound),
        rules=[
            @rule "associate-+r+" a c b (a + (b + c)) --> ((a + b) + c)
            @rule "associate-+l+" a c b ((a + b) + c) --> (a + (b + c))
            @rule "associate-+r-" a c b (a + (b - c)) --> ((a + b) - c)
            @rule "associate-+l-" a c b ((a - b) + c) --> (a - (b - c))
            @rule "associate--r+" a c b (a - (b + c)) --> ((a - b) - c)
            @rule "associate--l+" a c b ((a + b) - c) --> (a + (b - c))
            @rule "associate--l-" a c b ((a - b) - c) --> (a - (b + c))
            @rule "associate--r-" a c b (a - (b - c)) --> ((a - b) + c)
            @rule "associate-*r*" a c b (a * (b * c)) --> ((a * b) * c)
            @rule "associate-*l*" a c b ((a * b) * c) --> (a * (b * c))
            @rule "associate-*r/" a c b (a * (b / c)) --> ((a * b) / c)
            @rule "associate-*l/" a c b ((a / b) * c) --> ((a * c) / b)
            @rule "associate-/r*" a c b (a / (b * c)) --> ((a / b) / c)
            @rule "associate-/r/" a c b (a / (b / c)) --> ((a / b) * c)
            @rule "associate-/l/" a c b ((b / c) / a) --> (b / (a * c))
            @rule "associate-/l*" a c b ((b * c) / a) --> (b * (c / a))
        ],
    ),
    counting=(;
        groups=(:arithmetic, :simplify, :sound), rules=[@rule "count-2" x (x + x) --> (2 * x)]
    ),
    distributivity=(;
        groups=(:arithmetic, :simplify, :sound),
        rules=[
            @rule "distribute-lft-in" a c b (a * (b + c)) --> ((a * b) + (a * c))
            @rule "distribute-rgt-in" a c b (a * (b + c)) --> ((b * a) + (c * a))
            @rule "distribute-lft-out" a c b ((a * b) + (a * c)) --> (a * (b + c))
            @rule "distribute-lft-out--" a c b ((a * b) - (a * c)) --> (a * (b - c))
            @rule "distribute-rgt-out" a c b ((b * a) + (c * a)) --> (a * (b + c))
            @rule "distribute-rgt-out--" a c b ((b * a) - (c * a)) --> (a * (b - c))
            @rule "distribute-lft1-in" a b ((b * a) + a) --> ((b + 1) * a)
            @rule "distribute-rgt1-in" a c (a + (c * a)) --> ((c + 1) * a)
        ],
    ),
    distributivity_fp_safe=(;
        groups=(:arithmetic, :simplify, :fp_safe, :sound),
        rules=[
            @rule "distribute-lft-neg-in" a b -(a * b) --> ((-a) * b)
            @rule "distribute-rgt-neg-in" a b -(a * b) --> (a * (-b))
            @rule "distribute-lft-neg-out" a b ((-a) * b) --> -(a * b)
            @rule "distribute-rgt-neg-out" a b (a * (-b)) --> -(a * b)
            @rule "distribute-neg-in" a b -(a + b) --> ((-a) + (-b))
            @rule "distribute-neg-out" a b ((-a) + (-b)) --> -(a + b)
            @rule "distribute-frac-neg" a b ((-a) / b) --> -(a / b)
            @rule "distribute-frac-neg2" a b (a / (-b)) --> -(a / b)
            @rule "distribute-neg-frac" a b -(a / b) --> ((-a) / b)
            @rule "distribute-neg-frac2" a b -(a / b) --> (a / (-b))
        ],
    ),
    cancel_sign_fp_safe=(;
        groups=(:arithmetic, :simplify, :fp_safe, :sound),
        rules=[
            @rule "cancel-sign-sub" a c b (a - ((-b) * c)) --> (a + (b * c))
            @rule "cancel-sign-sub-inv" a c b (a - (b * c)) --> (a + ((-b) * c))
        ],
    ),
    difference_of_squares_canonicalize=(;
        groups=(:polynomials, :simplify, :sound),
        rules=[
            @rule "swap-sqr" a b ((a * b) * (a * b)) --> ((a * a) * (b * b))
            @rule "unswap-sqr" a b ((a * a) * (b * b)) --> ((a * b) * (a * b))
            @rule "difference-of-squares" a b ((a * a) - (b * b)) --> ((a + b) * (a - b))
            @rule "difference-of-sqr-1" a ((a * a) - 1) --> ((a + 1) * (a - 1))
            @rule "difference-of-sqr--1" a ((a * a) + -1) --> ((a + 1) * (a - 1))
            @rule "pow-sqr" a b ((a^b) * (a^b)) --> (a^(2 * b))
        ],
    ),
    sqr_pow_expand=(;
        groups=(:polynomials,), rules=[@rule "sqr-pow" a b (a^b) --> ((a^(b / 2)) * (a^(b / 2)))]
    ),
    difference_of_squares_flip=(;
        groups=(:polynomials,),
        rules=[
            @rule "flip-+" a b (a + b) --> (((a * a) - (b * b)) / (a - b))
            @rule "flip--" a b (a - b) --> (((a * a) - (b * b)) / (a + b))
        ],
    ),
    id_reduce=(;
        groups=(:arithmetic, :simplify, :sound),
        rules=[
            @rule "remove-double-div" a (1 / (1 / a)) --> a
            @rule "rgt-mult-inverse" a (a * (1 / a)) --> 1
            @rule "lft-mult-inverse" a ((1 / a) * a) --> 1
        ],
    ),
    id_reduce_fp_safe_nan=(;
        groups=(:arithmetic, :simplify, :fp_safe_nan, :sound),
        rules=[
            @rule "+-inverses" a (a - a) --> 0
            @rule "div0" a (0 / a) --> 0
            @rule "mul0-lft" a (0 * a) --> 0
            @rule "mul0-rgt" a (a * 0) --> 0
            @rule "*-inverses" a (a / a) --> 1
        ],
    ),
    id_reduce_fp_safe=(;
        groups=(:arithmetic, :simplify, :fp_safe, :sound),
        rules=[
            @rule "+-lft-identity" a (0 + a) --> a
            @rule "+-rgt-identity" a (a + 0) --> a
            @rule "--rgt-identity" a (a - 0) --> a
            @rule "sub0-neg" a (0 - a) --> (-a)
            @rule "remove-double-neg" a -(-a) --> a
            @rule "*-lft-identity" a (1 * a) --> a
            @rule "*-rgt-identity" a (a * 1) --> a
            @rule "/-rgt-identity" a (a / 1) --> a
            @rule "mul-1-neg" a (-1 * a) --> -a
        ],
    ),
    nan_transform_fp_safe=(;
        groups=(:arithmetic, :simplify, :fp_safe, :sound),
        rules=[
            @rule "sub-neg" a b (a - b) --> (a + (-b))
            @rule "unsub-neg" a b (a + (-b)) --> (a - b)
            @rule "neg-sub0" b (-b) --> (0 - b)
            @rule "neg-mul-1" a (-a) --> (-1 * a)
        ],
    ),
    id_transform_safe=(;
        groups=(:arithmetic, :sound),
        rules=[
            @rule "div-inv" a b (a / b) --> (a * (1 / b))
            @rule "un-div-inv" a b (a * (1 / b)) --> (a / b)
        ],
    ),
    id_transform_clear_num=(;
        groups=(:arithmetic,), rules=[@rule "clear-num" a b (a / b) --> (1 / (b / a))]
    ),
    id_transform_fp_safe=(;
        groups=(:arithmetic, :fp_safe, :sound), rules=[@rule "*-un-lft-identity" a a --> (1 * a)]
    ),
    difference_of_cubes=(;
        groups=(:polynomials, :sound),
        rules=[
            @rule "sum-cubes" a b ((a^3) + (b^3)) --> (((a * a) + ((b * b) - (a * b))) * (a + b))
            @rule "difference-cubes" a b ((a^3) - (b^3)) -->
                (((a * a) + ((b * b) + (a * b))) * (a - b))
            @rule "flip3-+" a b (a + b) --> (((a^3) + (b^3)) / ((a * a) + ((b * b) - (a * b))))
            @rule "flip3--" a b (a - b) --> (((a^3) - (b^3)) / ((a * a) + ((b * b) + (a * b))))
        ],
    ),
    fractions_distribute=(;
        groups=(:fractions, :simplify, :sound),
        rules=[
            @rule "div-sub" a c b ((a - b) / c) --> ((a / c) - (b / c))
            @rule "times-frac" a c b d ((a * b) / (c * d)) --> ((a / c) * (b / d))
        ],
    ),
    fractions_transform=(;
        groups=(:fractions, :sound),
        rules=[
            @rule "sub-div" a c b ((a / c) - (b / c)) --> ((a - b) / c)
            @rule "frac-add" a c b d ((a / b) + (c / d)) --> (((a * d) + (b * c)) / (b * d))
            @rule "frac-sub" a c b d ((a / b) - (c / d)) --> (((a * d) - (b * c)) / (b * d))
            @rule "frac-times" a c b d ((a / b) * (c / d)) --> ((a * c) / (b * d))
            @rule "frac-2neg" a b (a / b) --> ((-a) / (-b))
        ],
    ),
    squares_reduce=(;
        groups=(:arithmetic, :simplify, :sound),
        rules=[
            @rule "rem-square-sqrt" x (sqrt(x) * sqrt(x)) --> x
            @rule "rem-sqrt-square" x sqrt((x * x)) --> abs(x)
        ],
    ),
    squares_reduce_fp_sound=(;
        groups=(:arithmetic, :simplify, :fp_safe, :sound),
        rules=[
            @rule "sqr-neg" x ((-x) * (-x)) --> (x * x)
            @rule "sqr-abs" x (abs(x) * abs(x)) --> (x * x)
        ],
    ),
    abs_reduce=(;
        groups=(:arithmetic, :simplify, :fp_safe, :sound),
        rules=[
            @rule "abs-abs" x abs(abs(x)) --> abs(x)
            @rule "abs-sub" a b abs((a - b)) --> abs((b - a))
            @rule "abs-neg" x abs(-x) --> abs(x)
            @rule "abs-sqr" x abs((x * x)) --> (x * x)
            @rule "abs-mul" a b abs((a * b)) --> (abs(a) * abs(b))
            @rule "abs-div" a b abs((a / b)) --> (abs(a) / abs(b))
        ],
    ),
    abs_expand=(;
        groups=(:arithmetic, :fp_safe, :sound),
        rules=[
            @rule "neg-abs" x abs(x) --> abs(-x)
            @rule "mul-abs" a b (abs(a) * abs(b)) --> abs((a * b))
            @rule "div-abs" a b (abs(a) / abs(b)) --> abs((a / b))
        ],
    ),
    squares_transform_sound=(;
        groups=(:arithmetic, :sound),
        rules=[
            @rule "sqrt-pow2" y x (sqrt(x)^y) --> (x^(y / 2))
            @rule "sqrt-unprod" y x (sqrt(x) * sqrt(y)) --> sqrt((x * y))
            @rule "sqrt-undiv" y x (sqrt(x) / sqrt(y)) --> sqrt((x / y))
        ],
    ),
    squares_transform=(;
        groups=(:arithmetic,),
        rules=[
            @rule "sqrt-pow1" y x sqrt((x^y)) --> (x^(y / 2))
            @rule "sqrt-prod" y x sqrt((x * y)) --> (sqrt(x) * sqrt(y))
            @rule "sqrt-div" y x sqrt((x / y)) --> (sqrt(x) / sqrt(y))
            @rule "add-sqr-sqrt" x x --> (sqrt(x) * sqrt(x))
        ],
    ),
    cubes_reduce=(;
        groups=(:arithmetic, :simplify, :sound),
        rules=[
            @rule "rem-cube-cbrt" x (cbrt(x)^3) --> x
            @rule "rem-cbrt-cube" x cbrt((x^3)) --> x
            @rule "rem-3cbrt-lft" x ((cbrt(x) * cbrt(x)) * cbrt(x)) --> x
            @rule "rem-3cbrt-rft" x (cbrt(x) * (cbrt(x) * cbrt(x))) --> x
            @rule "cube-neg" x ((-x)^3) --> -(x^3)
        ],
    ),
    cubes_distribute=(;
        groups=(:arithmetic, :simplify, :sound),
        rules=[
            @rule "cube-prod" y x ((x * y)^3) --> ((x^3) * (y^3))
            @rule "cube-div" y x ((x / y)^3) --> ((x^3) / (y^3))
            @rule "cube-mult" x (x^3) --> (x * (x * x))
        ],
    ),
    cubes_transform=(;
        groups=(:arithmetic, :sound),
        rules=[
            @rule "cbrt-prod" y x cbrt((x * y)) --> (cbrt(x) * cbrt(y))
            @rule "cbrt-div" y x cbrt((x / y)) --> (cbrt(x) / cbrt(y))
            @rule "cbrt-unprod" y x (cbrt(x) * cbrt(y)) --> cbrt((x * y))
            @rule "cbrt-undiv" y x (cbrt(x) / cbrt(y)) --> cbrt((x / y))
            @rule "add-cube-cbrt" x x --> ((cbrt(x) * cbrt(x)) * cbrt(x))
            @rule "add-cbrt-cube" x x --> cbrt(((x * x) * x))
        ],
    ),
    cubes_canonicalize=(;
        groups=(:arithmetic, :simplify, :sound),
        rules=[@rule "cube-unmult" x (x * (x * x)) --> (x^3)],
    ),
    exp_expand_sound=(;
        groups=(:exponents, :sound), rules=[@rule "add-log-exp" x x --> log(exp(x))]
    ),
    exp_expand=(; groups=(:exponents,), rules=[@rule "add-exp-log" x x --> exp(log(x))]),
    exp_reduce=(;
        groups=(:exponents, :simplify, :sound),
        rules=[
            @rule "rem-exp-log" x exp(log(x)) --> x
            @rule "rem-log-exp" x log(exp(x)) --> x
        ],
    ),
    #exp_constants=(;
    #    groups=(:exponents, :simplify, :fp_safe, :sound),
    #    rules=[
    #        @rule "exp-0" exp(0) --> 1
    #        @rule "exp-1-e" E exp(1) --> E
    #        @rule "1-exp" 1 --> exp(0)
    #        @rule "e-exp-1" E E --> exp(1)
    #    ],
    #),
    exp_distribute=(;
        groups=(:exponents, :simplify, :sound),
        rules=[
            @rule "exp-sum" a b exp((a + b)) --> (exp(a) * exp(b))
            @rule "exp-neg" a exp(-a) --> (1 / exp(a))
            @rule "exp-diff" a b exp((a - b)) --> (exp(a) / exp(b))
        ],
    ),
    exp_factor=(;
        groups=(:exponents, :simplify, :sound),
        rules=[
            @rule "prod-exp" a b (exp(a) * exp(b)) --> exp((a + b))
            @rule "rec-exp" a (1 / exp(a)) --> exp(-a)
            @rule "div-exp" a b (exp(a) / exp(b)) --> exp((a - b))
            @rule "exp-prod" a b exp((a * b)) --> (exp(a)^b)
            @rule "exp-sqrt" a exp((a / 2)) --> sqrt(exp(a))
            @rule "exp-cbrt" a exp((a / 3)) --> cbrt(exp(a))
            @rule "exp-lft-sqr" a exp((a * 2)) --> (exp(a) * exp(a))
            @rule "exp-lft-cube" a exp((a * 3)) --> (exp(a)^3)
        ],
    ),
    pow_reduce=(;
        groups=(:exponents, :simplify, :sound), rules=[@rule "unpow-1" a (a^-1) --> (1 / a)]
    ),
    pow_reduce_fp_safe=(;
        groups=(:exponents, :simplify, :fp_safe, :sound),
        rules=[
            @rule "unpow1" a (a^1) --> a
            @rule "pow-base-1" a (1^a) --> 1
        ],
    ),
    pow_reduce_fp_safe_nan=(;
        groups=(:exponents, :simplify, :fp_safe_nan, :sound), rules=[@rule "unpow0" a (a^0) --> 1]
    ),
    pow_expand_fp_safe=(;
        groups=(:exponents, :fp_safe, :sound), rules=[@rule "pow1" a a --> (a^1)]
    ),
    pow_canonicalize=(;
        groups=(:exponents, :simplify, :sound),
        rules=[
            @rule "exp-to-pow" a b exp((log(a) * b)) --> (a^b)
            @rule "unpow1/2" a (a^1 / 2) --> sqrt(a)
            @rule "unpow2" a (a^2) --> (a * a)
            @rule "unpow3" a (a^3) --> ((a * a) * a)
            @rule "unpow1/3" a (a^1 / 3) --> cbrt(a)
            @rule "pow-plus" a b ((a^b) * a) --> (a^(b + 1))
        ],
    ),
    pow_transform_sound=(;
        groups=(:exponents, :sound),
        rules=[
            @rule "pow-exp" a b (exp(a)^b) --> exp((a * b))
            @rule "pow-prod-down" a c b ((b^a) * (c^a)) --> ((b * c)^a)
            @rule "pow-prod-up" a c b ((a^b) * (a^c)) --> (a^(b + c))
            @rule "pow-flip" a b (1 / (a^b)) --> (a^(-b))
            @rule "pow-neg" a b (a^(-b)) --> (1 / (a^b))
            @rule "pow-div" a c b ((a^b) / (a^c)) --> (a^(b - c))
        ],
    ),
    pow_specialize_sound=(;
        groups=(:exponents, :sound),
        rules=[
            @rule "pow1/2" a sqrt(a) --> (a^1 / 2)
            @rule "pow2" a (a * a) --> (a^2)
            @rule "pow1/3" a cbrt(a) --> (a^1 / 3)
            @rule "pow3" a ((a * a) * a) --> (a^3)
        ],
    ),
    pow_transform=(;
        groups=(:exponents,),
        rules=[
            @rule "pow-to-exp" a b (a^b) --> exp((log(a) * b))
            @rule "pow-sub" a c b (a^(b - c)) --> ((a^b) / (a^c))
            @rule "pow-pow" a c b ((a^b)^c) --> (a^(b * c))
            @rule "pow-unpow" a c b (a^(b * c)) --> ((a^b)^c)
            @rule "unpow-prod-up" a c b (a^(b + c)) --> ((a^b) * (a^c))
            @rule "unpow-prod-down" a c b ((b * c)^a) --> ((b^a) * (c^a))
        ],
    ),
    pow_transform_fp_safe_nan=(;
        groups=(:exponents, :simplify, :fp_safe_nan, :sound),
        rules=[@rule "pow-base-0" a (0^a) --> 0],
    ),
    pow_transform_fp_safe=(;
        groups=(:exponents, :fp_safe, :sound), rules=[@rule "inv-pow" a (1 / a) --> (a^-1)]
    ),
    #log_distribute_sound=(;
    #    groups=(:exponents, :simplify, :sound),
    #    rules=[
    #        @rule "log-rec" a log((1 / a)) --> -log(a)
    #        @rule "log-E" E log(E) --> 1
    #    ],
    #),
    log_distribute=(;
        groups=(:exponents,),
        rules=[
            @rule "log-prod" a b log((a * b)) --> (log(a) + log(b))
            @rule "log-div" a b log((a / b)) --> (log(a) - log(b))
            @rule "log-pow" a b log((a^b)) --> (b * log(a))
        ],
    ),
    log_factor=(;
        groups=(:exponents, :sound),
        rules=[
            @rule "sum-log" a b (log(a) + log(b)) --> log((a * b))
            @rule "diff-log" a b (log(a) - log(b)) --> log((a / b))
            @rule "neg-log" a -log(a) --> log((1 / a))
        ],
    ),
    trig_reduce_fp_sound=(;
        groups=(:trigonometry, :simplify, :fp_safe, :sound),
        rules=[
            @rule "sin-0" sin(0) --> 0
            @rule "cos-0" cos(0) --> 1
            @rule "tan-0" tan(0) --> 0
        ],
    ),
    trig_reduce_fp_sound_nan=(;
        groups=(:trigonometry, :simplify, :fp_safe_nan, :sound),
        rules=[
            @rule "sin-neg" x sin(-x) --> -sin(x)
            @rule "cos-neg" x cos(-x) --> cos(x)
            @rule "tan-neg" x tan(-x) --> -tan(x)
        ],
    ),
    trig_expand_fp_safe=(;
        groups=(:trignometry, :fp_safe, :sound),
        rules=[
            @rule "sqr-sin-b" x (sin(x) * sin(x)) --> (1 - (cos(x) * cos(x)))
            @rule "sqr-cos-b" x (cos(x) * cos(x)) --> (1 - (sin(x) * sin(x)))
        ],
    ),
    #trig_inverses = (; groups=(:trigonometry, :sound,), rules=[
    #    @rule "sin-asin" x sin(asin(x)) --> x
    #    @rule "cos-acos" x cos(acos(x)) --> x
    #    @rule "tan-atan" x tan(atan(x)) --> x
    #    @rule "atan-tan" x atan(tan(x)) --> (xremainderpi)
    #    @rule "asin-sin" x asin(sin(x)) --> (abs(((x+(pi/2))remainder(2*pi)))-(pi/2))
    #    @rule "acos-cos" x acos(cos(x)) --> abs((xremainder(2*pi)))
    #]),
    trig_inverses_simplified=(;
        groups=(:trigonometry,),
        rules=[
            @rule "atan-tan-s" x atan(tan(x)) --> x
            @rule "asin-sin-s" x asin(sin(x)) --> x
            @rule "acos-cos-s" x acos(cos(x)) --> x
        ],
    ),
    trig_reduce_sound=(;
        groups=(:trigonometry, :simplify, :sound),
        rules=[
            @rule "cos-sin-sum" a ((cos(a) * cos(a)) + (sin(a) * sin(a))) --> 1
            @rule "1-sub-cos" a (1 - (cos(a) * cos(a))) --> (sin(a) * sin(a))
            @rule "1-sub-sin" a (1 - (sin(a) * sin(a))) --> (cos(a) * cos(a))
            @rule "-1-add-cos" a ((cos(a) * cos(a)) + -1) --> -(sin(a) * sin(a))
            @rule "-1-add-sin" a ((sin(a) * sin(a)) + -1) --> -(cos(a) * cos(a))
            @rule "sub-1-cos" a ((cos(a) * cos(a)) - 1) --> -(sin(a) * sin(a))
            @rule "sub-1-sin" a ((sin(a) * sin(a)) - 1) --> -(cos(a) * cos(a))
            @rule "sin-pi/6" sin((pi / 6)) --> 1 / 2
            @rule "sin-pi/4" sin((pi / 4)) --> (sqrt(2) / 2)
            @rule "sin-pi/3" sin((pi / 3)) --> (sqrt(3) / 2)
            @rule "sin-pi/2" sin((pi / 2)) --> 1
            @rule "sin-pi" sin(pi) --> 0
            @rule "sin-+pi" x sin((x + pi)) --> -sin(x)
            @rule "sin-+pi/2" x sin((x + (pi / 2))) --> cos(x)
            @rule "cos-pi/6" cos((pi / 6)) --> (sqrt(3) / 2)
            @rule "cos-pi/4" cos((pi / 4)) --> (sqrt(2) / 2)
            @rule "cos-pi/3" cos((pi / 3)) --> 1 / 2
            @rule "cos-pi/2" cos((pi / 2)) --> 0
            @rule "cos-pi" cos(pi) --> -1
            @rule "cos-+pi" x cos((x + pi)) --> -cos(x)
            @rule "cos-+pi/2" x cos((x + (pi / 2))) --> -sin(x)
            @rule "tan-pi/6" tan((pi / 6)) --> (1 / sqrt(3))
            @rule "tan-pi/4" tan((pi / 4)) --> 1
            @rule "tan-pi/3" tan((pi / 3)) --> sqrt(3)
            @rule "tan-pi" tan(pi) --> 0
            @rule "tan-+pi" x tan((x + pi)) --> tan(x)
            @rule "hang-0p-tan" a (sin(a) / (1 + cos(a))) --> tan((a / 2))
            @rule "hang-0m-tan" a (-sin(a) / (1 + cos(a))) --> tan((-a / 2))
            @rule "hang-p0-tan" a ((1 - cos(a)) / sin(a)) --> tan((a / 2))
            @rule "hang-m0-tan" a ((1 - cos(a)) / (-sin(a))) --> tan((-a / 2))
            @rule "hang-p-tan" a b ((sin(a) + sin(b)) / (cos(a) + cos(b))) --> tan(((a + b) / 2))
            @rule "hang-m-tan" a b ((sin(a) - sin(b)) / (cos(a) + cos(b))) --> tan(((a - b) / 2))
        ],
    ),
    trig_reduce=(;
        groups=(:trigonometry,), rules=[@rule "tan-+pi/2" x tan((x + (pi / 2))) --> (-1 / tan(x))]
    ),
    trig_expand_sound=(;
        groups=(:trigonometry, :sound),
        rules=[
            @rule "sin-sum" y x sin((x + y)) --> ((sin(x) * cos(y)) + (cos(x) * sin(y)))
            @rule "cos-sum" y x cos((x + y)) --> ((cos(x) * cos(y)) - (sin(x) * sin(y)))
            @rule "tan-sum" y x tan((x + y)) --> ((tan(x) + tan(y)) / (1 - (tan(x) * tan(y))))
            @rule "sin-diff" y x sin((x - y)) --> ((sin(x) * cos(y)) - (cos(x) * sin(y)))
            @rule "cos-diff" y x cos((x - y)) --> ((cos(x) * cos(y)) + (sin(x) * sin(y)))
            @rule "sin-2" x sin((2 * x)) --> (2 * (sin(x) * cos(x)))
            @rule "sin-3" x sin((3 * x)) --> ((3 * sin(x)) - (4 * (sin(x)^3)))
            @rule "2-sin" x (2 * (sin(x) * cos(x))) --> sin((2 * x))
            @rule "3-sin" x ((3 * sin(x)) - (4 * (sin(x)^3))) --> sin((3 * x))
            @rule "cos-2" x cos((2 * x)) --> ((cos(x) * cos(x)) - (sin(x) * sin(x)))
            @rule "cos-3" x cos((3 * x)) --> ((4 * (cos(x)^3)) - (3 * cos(x)))
            @rule "2-cos" x ((cos(x) * cos(x)) - (sin(x) * sin(x))) --> cos((2 * x))
            @rule "3-cos" x ((4 * (cos(x)^3)) - (3 * cos(x))) --> cos((3 * x))
        ],
    ),
    trig_expand_sound2=(;
        groups=(:trigonometry, :sound),
        rules=[
            @rule "sqr-sin-a" x (sin(x) * sin(x)) --> (1 / 2 - (1 / 2 * cos((2 * x))))
            @rule "sqr-cos-a" x (cos(x) * cos(x)) --> (1 / 2 + (1 / 2 * cos((2 * x))))
            @rule "diff-sin" y x (sin(x) - sin(y)) -->
                (2 * (sin(((x - y) / 2)) * cos(((x + y) / 2))))
            @rule "diff-cos" y x (cos(x) - cos(y)) -->
                (-2 * (sin(((x - y) / 2)) * sin(((x + y) / 2))))
            @rule "sum-sin" y x (sin(x) + sin(y)) -->
                (2 * (sin(((x + y) / 2)) * cos(((x - y) / 2))))
            @rule "sum-cos" y x (cos(x) + cos(y)) -->
                (2 * (cos(((x + y) / 2)) * cos(((x - y) / 2))))
            @rule "cos-mult" y x (cos(x) * cos(y)) --> ((cos((x + y)) + cos((x - y))) / 2)
            @rule "sin-mult" y x (sin(x) * sin(y)) --> ((cos((x - y)) - cos((x + y))) / 2)
            @rule "sin-cos-mult" y x (sin(x) * cos(y)) --> ((sin((x - y)) + sin((x + y))) / 2)
            @rule "diff-atan" y x (atan(x) - atan(y)) --> ((x - y)atan2(1 + (x * y)))
            @rule "sum-atan" y x (atan(x) + atan(y)) --> ((x + y)atan2(1 - (x * y)))
            @rule "tan-quot" x tan(x) --> (sin(x) / cos(x))
            @rule "quot-tan" x (sin(x) / cos(x)) --> tan(x)
            @rule "tan-2" x tan((2 * x)) --> ((2 * tan(x)) / (1 - (tan(x) * tan(x))))
            @rule "2-tan" x ((2 * tan(x)) / (1 - (tan(x) * tan(x)))) --> tan((2 * x))
        ],
    ),
    trig_expand=(;
        groups=(:trigonometry,),
        rules=[
            @rule "tan-hang-p" a b tan(((a + b) / 2)) --> ((sin(a) + sin(b)) / (cos(a) + cos(b)))
            @rule "tan-hang-m" a b tan(((a - b) / 2)) --> ((sin(a) - sin(b)) / (cos(a) + cos(b)))
        ],
    ),
    atrig_expand=(;
        groups=(:trigonometry, :sound),
        rules=[
            @rule "cos-asin" x cos(asin(x)) --> sqrt((1 - (x * x)))
            @rule "tan-asin" x tan(asin(x)) --> (x / sqrt((1 - (x * x))))
            @rule "sin-acos" x sin(acos(x)) --> sqrt((1 - (x * x)))
            @rule "tan-acos" x tan(acos(x)) --> (sqrt((1 - (x * x))) / x)
            @rule "sin-atan" x sin(atan(x)) --> (x / sqrt((1 + (x * x))))
            @rule "cos-atan" x cos(atan(x)) --> (1 / sqrt((1 + (x * x))))
            @rule "asin-acos" x asin(x) --> ((pi / 2) - acos(x))
            @rule "acos-asin" x acos(x) --> ((pi / 2) - asin(x))
            @rule "asin-neg" x asin(-x) --> -asin(x)
            @rule "acos-neg" x acos(-x) --> (pi - acos(x))
            @rule "atan-neg" x atan(-x) --> -atan(x)
        ],
    ),
    htrig_reduce=(;
        groups=(:hyperbolic, :simplify, :sound),
        rules=[
            @rule "sinh-def" x sinh(x) --> ((exp(x) - exp(-x)) / 2)
            @rule "cosh-def" x cosh(x) --> ((exp(x) + exp(-x)) / 2)
            @rule "tanh-def-a" x tanh(x) --> ((exp(x) - exp(-x)) / (exp(x) + exp(-x)))
            @rule "tanh-def-b" x tanh(x) --> ((exp((2 * x)) - 1) / (exp((2 * x)) + 1))
            @rule "tanh-def-c" x tanh(x) --> ((1 - exp((-2 * x))) / (1 + exp((-2 * x))))
            @rule "sinh-cosh" x ((cosh(x) * cosh(x)) - (sinh(x) * sinh(x))) --> 1
            @rule "sinh-+-cosh" x (cosh(x) + sinh(x)) --> exp(x)
            @rule "sinh---cosh" x (cosh(x) - sinh(x)) --> exp(-x)
        ],
    ),
    htrig_expand_sound=(;
        groups=(:hyperbolic, :sound),
        rules=[
            @rule "sinh-undef" x (exp(x) - exp(-x)) --> (2 * sinh(x))
            @rule "cosh-undef" x (exp(x) + exp(-x)) --> (2 * cosh(x))
            @rule "tanh-undef" x ((exp(x) - exp(-x)) / (exp(x) + exp(-x))) --> tanh(x)
            @rule "cosh-sum" y x cosh((x + y)) --> ((cosh(x) * cosh(y)) + (sinh(x) * sinh(y)))
            @rule "cosh-diff" y x cosh((x - y)) --> ((cosh(x) * cosh(y)) - (sinh(x) * sinh(y)))
            @rule "cosh-2" x cosh((2 * x)) --> ((sinh(x) * sinh(x)) + (cosh(x) * cosh(x)))
            @rule "cosh-1/2" x cosh((x / 2)) --> sqrt(((cosh(x) + 1) / 2))
            @rule "sinh-sum" y x sinh((x + y)) --> ((sinh(x) * cosh(y)) + (cosh(x) * sinh(y)))
            @rule "sinh-diff" y x sinh((x - y)) --> ((sinh(x) * cosh(y)) - (cosh(x) * sinh(y)))
            @rule "sinh-2" x sinh((2 * x)) --> (2 * (sinh(x) * cosh(x)))
            @rule "sinh-1/2" x sinh((x / 2)) --> (sinh(x) / sqrt((2 * (cosh(x) + 1))))
            @rule "tanh-2" x tanh((2 * x)) --> ((2 * tanh(x)) / (1 + (tanh(x) * tanh(x))))
            @rule "tanh-1/2" x tanh((x / 2)) --> (sinh(x) / (cosh(x) + 1))
            @rule "sum-sinh" y x (sinh(x) + sinh(y)) -->
                (2 * (sinh(((x + y) / 2)) * cosh(((x - y) / 2))))
            @rule "sum-cosh" y x (cosh(x) + cosh(y)) -->
                (2 * (cosh(((x + y) / 2)) * cosh(((x - y) / 2))))
            @rule "diff-sinh" y x (sinh(x) - sinh(y)) -->
                (2 * (cosh(((x + y) / 2)) * sinh(((x - y) / 2))))
            @rule "diff-cosh" y x (cosh(x) - cosh(y)) -->
                (2 * (sinh(((x + y) / 2)) * sinh(((x - y) / 2))))
            @rule "tanh-sum" y x tanh((x + y)) -->
                ((tanh(x) + tanh(y)) / (1 + (tanh(x) * tanh(y))))
        ],
    ),
    htrig_expand=(;
        groups=(:hyperbolic,),
        rules=[@rule "tanh-1/2*" x tanh((x / 2)) --> ((cosh(x) - 1) / sinh(x))],
    ),
    htrig_expand_fp_safe=(;
        groups=(:hyperbolic, :fp_safe, :sound),
        rules=[
            @rule "sinh-neg" x sinh(-x) --> -sinh(x)
            @rule "sinh-0" sinh(0) --> 0
            @rule "cosh-neg" x cosh(-x) --> cosh(x)
            @rule "cosh-0" cosh(0) --> 1
        ],
    ),
    ahtrig_expand_sound=(;
        groups=(:hyperbolic, :sound),
        rules=[
            @rule "asinh-def" x asinh(x) --> log((x + sqrt(((x * x) + 1))))
            @rule "acosh-def" x acosh(x) --> log((x + sqrt(((x * x) - 1))))
            @rule "atanh-def" x atanh(x) --> (log(((1 + x) / (1 - x))) / 2)
            @rule "sinh-asinh" x sinh(asinh(x)) --> x
            @rule "sinh-acosh" x sinh(acosh(x)) --> sqrt(((x * x) - 1))
            @rule "sinh-atanh" x sinh(atanh(x)) --> (x / sqrt((1 - (x * x))))
            @rule "cosh-asinh" x cosh(asinh(x)) --> sqrt(((x * x) + 1))
            @rule "cosh-acosh" x cosh(acosh(x)) --> x
            @rule "cosh-atanh" x cosh(atanh(x)) --> (1 / sqrt((1 - (x * x))))
            @rule "tanh-asinh" x tanh(asinh(x)) --> (x / sqrt((1 + (x * x))))
            @rule "tanh-acosh" x tanh(acosh(x)) --> (sqrt(((x * x) - 1)) / x)
            @rule "tanh-atanh" x tanh(atanh(x)) --> x
        ],
    ),
    ahtrig_expand=(;
        groups=(:hyperbolic,),
        rules=[
            @rule "asinh-2" x acosh(((2 * (x * x)) + 1)) --> (2 * asinh(x))
            @rule "acosh-2" x acosh(((2 * (x * x)) - 1)) --> (2 * acosh(x))
        ],
    ),
    compare_reduce=(;
        groups=(:bools, :simplify, :fp_safe_nan, :sound),
        rules=[
            @rule "lt-same" x (x < x) --> false
            @rule "gt-same" x (x > x) --> false
            @rule "lte-same" x (x <= x) --> true
            @rule "gte-same" x (x >= x) --> true
            @rule "not-lt" y x not((x < y)) --> (x >= y)
            @rule "not-gt" y x not((x > y)) --> (x <= y)
            @rule "not-lte" y x not((x <= y)) --> (x > y)
            @rule "not-gte" y x not((x >= y)) --> (x < y)
        ],
    ),
    # branch_reduce = (; groups=(:branches, :simplify, :fp_safe, :sound,), rules=[
    #     @rule "if-true" y x (if (true) x y) --> x
    #     @rule "if-false" y x (if (false) x y) --> y
    #     @rule "if-same" x a (if a x x) --> x
    #     @rule "if-not" y x a (if (not a) x y) --> (if a y x)
    #     @rule "if-if-or" y x a b (if a x (if b x y)) --> (if (or a b) x y)
    #     @rule "if-if-or-not" y x a b (if a x (if b y x)) --> (if (or a (not b)) x y)
    #     @rule "if-if-and" y x a b (if a (if b x y) y) --> (if (and a b) x y)
    #     @rule "if-if-and-not" y x a b (if a (if b y x) y) --> (if (and a (not b)) x y)
    # ]),
)

"Rules that are used to generate new candidate expressions."
REWRITE_THEORY = convert(Vector{RewriteRule}, mapreduce(t -> t.rules, ∪, theories))

"Rules that are used to simplify generated candidate expressions. This is a subset of [`REWRITE_THEORY`](@ref)."
SIMPLIFY_THEORY = convert(
    Vector{RewriteRule}, mapreduce(t -> t.rules, ∪, filter(t -> (:simplify ∈ t.groups), theories))
)
