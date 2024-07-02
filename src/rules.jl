using Metatheory

theories = (;
    commutativity = [
      @rule "+-commutative" a b (a+b) --> (b+a)
      @rule "*-commutative" a b (a*b) --> (b*a)
    ],
    associativity = [
       @rule "associate-+r+" a c b (a+(b+c)) --> ((a+b)+c)
       @rule "associate-+l+" a c b ((a+b)+c) --> (a+(b+c))
       @rule "associate-+r-" a c b (a+(b-c)) --> ((a+b)-c)
       @rule "associate-+l-" a c b ((a-b)+c) --> (a-(b-c))
       @rule "associate--r+" a c b (a-(b+c)) --> ((a-b)-c)
       @rule "associate--l+" a c b ((a+b)-c) --> (a+(b-c))
       @rule "associate--l-" a c b ((a-b)-c) --> (a-(b+c))
       @rule "associate--r-" a c b (a-(b-c)) --> ((a-b)+c)
       @rule "associate-*r*" a c b (a*(b*c)) --> ((a*b)*c)
       @rule "associate-*l*" a c b ((a*b)*c) --> (a*(b*c))
       @rule "associate-*r/" a c b (a*(b/c)) --> ((a*b)/c)
       @rule "associate-*l/" a c b ((a/b)*c) --> ((a*c)/b)
       @rule "associate-/r*" a c b (a/(b*c)) --> ((a/b)/c)
       @rule "associate-/r/" a c b (a/(b/c)) --> ((a/b)*c)
       @rule "associate-/l/" a c b ((b/c)/a) --> (b/(a*c))
       @rule "associate-/l*" a c b ((b*c)/a) --> (b*(c/a))
    ],
    counting = [
       @rule "count-2" x (x+x) --> (2*x)
    ],
    distributivity = [
       @rule "distribute-lft-in" a c b (a*(b+c)) --> ((a*b)+(a*c))
       @rule "distribute-rgt-in" a c b (a*(b+c)) --> ((b*a)+(c*a))
       @rule "distribute-lft-out" a c b ((a*b)+(a*c)) --> (a*(b+c))
       @rule "distribute-lft-out--" a c b ((a*b)-(a*c)) --> (a*(b-c))
       @rule "distribute-rgt-out" a c b ((b*a)+(c*a)) --> (a*(b+c))
       @rule "distribute-rgt-out--" a c b ((b*a)-(c*a)) --> (a*(b-c))
       @rule "distribute-lft1-in" a b ((b*a)+a) --> ((b+1)*a)
       @rule "distribute-rgt1-in" a c (a+(c*a)) --> ((c+1)*a)
    ],
    distributivity_fp_safe = [
       @rule "distribute-lft-neg-in" a b  -(a*b) --> ((-a)*b)
       @rule "distribute-rgt-neg-in" a b  -(a*b) --> (a*(-b))
       @rule "distribute-lft-neg-out" a b (-a)*b --> -(a*b)
       @rule "distribute-rgt-neg-out" a b a*(-b) --> -(a*b)
       @rule "distribute-neg-in" a b      -(a+b) --> (-a)+(-b)
       @rule "distribute-neg-out" a b     (-a)+(-b) --> -(a+b)
       @rule "distribute-frac-neg" a b    (-a)/b --> -(a/b)
       @rule "distribute-frac-neg2" a b   a/(-b) --> -(a/b)
       @rule "distribute-neg-frac" a b    -(a/b) --> (-a)/b
       @rule "distribute-neg-frac2" a b   -(a/b) --> a/(-b)
    ],
    cancel_sign_fp_safe = [
       @rule "cancel-sign-sub" a c b     a-((-b)*c) --> a+(b*c)
       @rule "cancel-sign-sub-inv" a c b a-(b*c) --> a+(-b)*c
    ],
    difference_of_squares_canonicalize = [
       @rule "swap-sqr" a b ((a*b)*(a*b)) --> ((a*a)*(b*b))
       @rule "unswap-sqr" a b ((a*a)*(b*b)) --> ((a*b)*(a*b))
       @rule "difference-of-squares" a b ((a*a)-(b*b)) --> ((a+b)*(a-b))
       @rule "difference-of-sqr-1" a ((a*a)-1) --> ((a+1)*(a-1))
       @rule "difference-of-sqr--1" a ((a*a)+(-1)) --> ((a+1)*(a-1))
       @rule "pow-sqr" a b ((a^b)*(a^b)) --> (a^(2*b))
    ],
    #sqr_pow_expand = [
    #   @rule "sqr-pow" a b (a^b) --> ((a^(b/2))*(a^(b/2)))
    #],
    difference_of_squares_flip = [
       @rule "flip-+" a b a+b --> (a*a-b*b)/(a-b)
       @rule "flip--" a b a-b --> (a*a-b*b)/(a+b)
    ],
    id_reduce = [
       @rule "remove-double-div" a (1/(1/a)) --> a
       @rule "rgt-mult-inverse" a (a*(1/a)) --> 1
       @rule "lft-mult-inverse" a ((1/a)*a) --> 1
    ],
    id_reduce_fp_safe_nan = [
       @rule "+-inverses" a (a-a) --> 0
       @rule "div0" a (0/a) --> 0
       @rule "mul0-lft" a (0*a) --> 0
       @rule "mul0-rgt" a (a*0) --> 0
       @rule "*-inverses" a (a/a) --> 1
    ],
    id_reduce_fp_safe = [
       @rule "+-lft-identity" a (0+a) --> a
       @rule "+-rgt-identity" a (a+0) --> a
       @rule "--rgt-identity" a (a-0) --> a
       @rule "sub0-neg" a (0-a) --> -a
       @rule "remove-double-neg" a -(-a) --> a
       @rule "*-lft-identity" a (1*a) --> a
       @rule "*-rgt-identity" a (a*1) --> a
       @rule "/-rgt-identity" a (a/1) --> a
       @rule "mul-1-neg" a (-1*a) --> -a
    ],
    nan_transform_fp_safe = [
       @rule "sub-neg" a b (a-b) --> (a+(-b))
       @rule "unsub-neg" a b (a+(-b)) --> (a-b)
       @rule "neg-sub0" b (-b) --> (0-b)
       @rule "neg-mul-1" a (-a) --> (-1*a)
    ],
    #id_transform_safe = [
    #   @rule "div-inv" a b (a/b) --> (a*(1/b))
    #   @rule "un-div-inv" a b (a*(1/b)) --> (a/b)
    #],
    #id_transform_clear_num = [
    #   @rule "clear-num" a b (a/b) --> (1/(b/a))
    #],
    #id_transform_fp_safe = [
    #   @rule "*-un-lft-identity" a a --> (1*a)
    #],
    #difference_of_cubes = [
    #   @rule "sum-cubes" a b ((a^3)+(b^3)) --> (((a*a)+((b*b)-(a*b)))*(a+b))
    #   @rule "difference-cubes" a b ((a^3)-(b^3)) --> (((a*a)+((b*b)+(a*b)))*(a-b))
    #   @rule "flip3-+" a b (a+b) --> (((a^3)+(b^3))/((a*a)+((b*b)-(a*b))))
    #   @rule "flip3--" a b (a-b) --> (((a^3)-(b^3))/((a*a)+((b*b)+(a*b))))
    #],
    fractions_distribute = [
       @rule "div-sub" a c b ((a-b)/c) --> ((a/c)-(b/c))
       @rule "times-frac" a c b d ((a*b)/(c*d)) --> ((a/c)*(b/d))
    ],
    fractions_transform = [
       @rule "sub-div" a c b ((a/c)-(b/c)) --> ((a-b)/c)
       @rule "frac-add" a c b d ((a/b)+(c/d)) --> (((a*d)+(b*c))/(b*d))
       @rule "frac-sub" a c b d ((a/b)-(c/d)) --> (((a*d)-(b*c))/(b*d))
       @rule "frac-times" a c b d ((a/b)*(c/d)) --> ((a*c)/(b*d))
       @rule "frac-2neg" a b (a/b) --> (neg(a)/neg(b))
    ],
    squares_reduce = [
       @rule "rem-square-sqrt" x (sqrt(x)*sqrt(x)) --> x
       @rule "rem-sqrt-square" x sqrt((x*x)) --> fabs(x)
    ],
    #squares_reduce_fp_sound = [
    #   @rule "sqr-neg" x (neg(x)*neg(x)) --> (x*x)
    #   @rule "sqr-abs" x (fabs(x)*fabs(x)) --> (x*x)
    #],
    #fabs_reduce = [
    #   @rule "fabs-fabs" x fabs(fabs(x)) --> fabs(x)
    #   @rule "fabs-sub" a b fabs((a-b)) --> fabs((b-a))
    #   @rule "fabs-neg" x fabs(neg(x)) --> fabs(x)
    #   @rule "fabs-sqr" x fabs((x*x)) --> (x*x)
    #   @rule "fabs-mul" a b fabs((a*b)) --> (fabs(a)*fabs(b))
    #   @rule "fabs-div" a b fabs((a/b)) --> (fabs(a)/fabs(b))
    #],
    #fabs_expand = [
    #   @rule "neg-fabs" x fabs(x) --> fabs(neg(x))
    #   @rule "mul-fabs" a b (fabs(a)*fabs(b)) --> fabs((a*b))
    #   @rule "div-fabs" a b (fabs(a)/fabs(b)) --> fabs((a/b))
    #],
    #squares_transform_sound = [
    #   @rule "sqrt-pow2" y x (sqrt(x)^y) --> (x^(y/2))
    #   @rule "sqrt-unprod" y x (sqrt(x)*sqrt(y)) --> sqrt((x*y))
    #   @rule "sqrt-undiv" y x (sqrt(x)/sqrt(y)) --> sqrt((x/y))
    #],
    squares_transform = [
       @rule "sqrt-pow1" y x sqrt((x^y)) --> (x^(y/2))
       @rule "sqrt-prod" y x sqrt((x*y)) --> (sqrt(x)*sqrt(y))
       @rule "sqrt-div" y x sqrt((x/y)) --> (sqrt(x)/sqrt(y))
       @rule "add-sqr-sqrt" x x --> (sqrt(x)*sqrt(x))
    ],
    #cubes_reduce = [
    #   @rule "rem-cube-cbrt" x (cbrt(x)^3) --> x
    #   @rule "rem-cbrt-cube" x cbrt((x^3)) --> x
    #   @rule "rem-3cbrt-lft" x ((cbrt(x)*cbrt(x))*cbrt(x)) --> x
    #   @rule "rem-3cbrt-rft" x (cbrt(x)*(cbrt(x)*cbrt(x))) --> x
    #   @rule "cube-neg" x (neg(x)^3) --> neg((x^3))
    #],
    #cubes_distribute = [
    #   @rule "cube-prod" y x ((x*y)^3) --> ((x^3)*(y^3))
    #   @rule "cube-div" y x ((x/y)^3) --> ((x^3)/(y^3))
    #   @rule "cube-mult" x (x^3) --> (x*(x*x))
    #],
    #cubes_transform = [
    #   @rule "cbrt-prod" y x cbrt((x*y)) --> (cbrt(x)*cbrt(y))
    #   @rule "cbrt-div" y x cbrt((x/y)) --> (cbrt(x)/cbrt(y))
    #   @rule "cbrt-unprod" y x (cbrt(x)*cbrt(y)) --> cbrt((x*y))
    #   @rule "cbrt-undiv" y x (cbrt(x)/cbrt(y)) --> cbrt((x/y))
    #   @rule "add-cube-cbrt" x x --> ((cbrt(x)*cbrt(x))*cbrt(x))
    #   @rule "add-cbrt-cube" x x --> cbrt(((x*x)*x))
    #],
    #cubes_canonicalize = [
    #   @rule "cube-unmult" x (x*(x*x)) --> (x^3)
    #],
    #exp_expand_sound = [
    #   @rule "add-log-exp" x x --> log(exp(x))
    #],
    #exp_expand = [
    #   @rule "add-exp-log" x x --> exp(log(x))
    #],
    #exp_reduce = [
    #   @rule "rem-exp-log" x exp(log(x)) --> x
    #   @rule "rem-log-exp" x log(exp(x)) --> x
    #],
    #exp_constants = [
    #   @rule "exp-0"  exp(0) --> 1
    #   @rule "exp-1-e" E exp(1) --> E
    #   @rule "1-exp"  1 --> exp(0)
    #   @rule "e-exp-1" E E --> exp(1)
    #],
    #exp_distribute = [
    #   @rule "exp-sum" a b exp((a+b)) --> (exp(a)*exp(b))
    #   @rule "exp-neg" a exp(neg(a)) --> (1/exp(a))
    #   @rule "exp-diff" a b exp((a-b)) --> (exp(a)/exp(b))
    #],
    #exp_factor = [
    #   @rule "prod-exp" a b (exp(a)*exp(b)) --> exp((a+b))
    #   @rule "rec-exp" a (1/exp(a)) --> exp(neg(a))
    #   @rule "div-exp" a b (exp(a)/exp(b)) --> exp((a-b))
    #   @rule "exp-prod" a b exp((a*b)) --> (exp(a)^b)
    #   @rule "exp-sqrt" a exp((a/2)) --> sqrt(exp(a))
    #   @rule "exp-cbrt" a exp((a/3)) --> cbrt(exp(a))
    #   @rule "exp-lft-sqr" a exp((a*2)) --> (exp(a)*exp(a))
    #   @rule "exp-lft-cube" a exp((a*3)) --> (exp(a)^3)
    #],
    #pow_reduce = [
    #   @rule "unpow-1" a (a^-1) --> (1/a)
    #],
    pow_reduce_fp_safe = [
       @rule "unpow1" a (a^1) --> a
       @rule "pow-base-1" a (1^a) --> 1
    ],
    #pow_reduce_fp_safe_nan = [
    #   @rule "unpow0" a (a^0) --> 1
    #],
    #pow_expand_fp_safe = [
    #   @rule "pow1" a a --> (a^1)
    #],
    pow_canonicalize = [
       @rule "exp-to-pow" a b exp((log(a)*b)) --> (a^b)
       @rule "unpow1/2" a (a^1/2) --> sqrt(a)
       @rule "unpow2" a (a^2) --> (a*a)
       @rule "unpow3" a (a^3) --> ((a*a)*a)
       @rule "unpow1/3" a (a^1/3) --> cbrt(a)
       @rule "pow-plus" a b ((a^b)*a) --> (a^(b+1))
    ],
    #pow_transform_sound = [
    #   @rule "pow-exp" a b (exp(a)^b) --> exp((a*b))
    #   @rule "pow-prod-down" a c b ((b^a)*(c^a)) --> ((b*c)^a)
    #   @rule "pow-prod-up" a c b ((a^b)*(a^c)) --> (a^(b+c))
    #   @rule "pow-flip" a b (1/(a^b)) --> (a^neg(b))
    #   @rule "pow-neg" a b (a^neg(b)) --> (1/(a^b))
    #   @rule "pow-div" a c b ((a^b)/(a^c)) --> (a^(b-c))
    #],
    pow_specialize_sound = [
       @rule "pow1/2" a sqrt(a) --> (a^1/2)
       @rule "pow2" a (a*a) --> (a^2)
       @rule "pow1/3" a cbrt(a) --> (a^1/3)
       @rule "pow3" a ((a*a)*a) --> (a^3)
    ],
    #pow_transform = [
    #   @rule "pow-to-exp" a b (a^b) --> exp((log(a)*b))
    #   @rule "pow-sub" a c b (a^(b-c)) --> ((a^b)/(a^c))
    #   @rule "pow-pow" a c b ((a^b)^c) --> (a^(b*c))
    #   @rule "pow-unpow" a c b (a^(b*c)) --> ((a^b)^c)
    #   @rule "unpow-prod-up" a c b (a^(b+c)) --> ((a^b)*(a^c))
    #   @rule "unpow-prod-down" a c b ((b*c)^a) --> ((b^a)*(c^a))
    #],
    #pow_transform_fp_safe_nan = [
    #   @rule "pow-base-0" a (0^a) --> 0
    #],
    #pow_transform_fp_safe = [
    #   @rule "inv-pow" a (1/a) --> (a^-1)
    #],
    #log_distribute_sound = [
    #   @rule "log-rec" a log((1/a)) --> neg(log(a))
    #   @rule "log-E" E log(E) --> 1
    #],
    #log_distribute = [
    #   @rule "log-prod" a b log((a*b)) --> (log(a)+log(b))
    #   @rule "log-div" a b log((a/b)) --> (log(a)-log(b))
    #   @rule "log-pow" a b log((a^b)) --> (b*log(a))
    #],
    #log_factor = [
    #   @rule "sum-log" a b (log(a)+log(b)) --> log((a*b))
    #   @rule "diff-log" a b (log(a)-log(b)) --> log((a/b))
    #   @rule "neg-log" a neg(log(a)) --> log((1/a))
    #],
    #trig_reduce_fp_sound = [
    #   @rule "sin-0"  sin(0) --> 0
    #   @rule "cos-0"  cos(0) --> 1
    #   @rule "tan-0"  tan(0) --> 0
    #],
    #trig_reduce_fp_sound_nan = [
    #   @rule "sin-neg" x sin(neg(x)) --> neg(sin(x))
    #   @rule "cos-neg" x cos(neg(x)) --> cos(x)
    #   @rule "tan-neg" x tan(neg(x)) --> neg(tan(x))
    #],
    #trig_expand_fp_safe = [
    #   @rule "sqr-sin-b" x (sin(x)*sin(x)) --> (1-(cos(x)*cos(x)))
    #   @rule "sqr-cos-b" x (cos(x)*cos(x)) --> (1-(sin(x)*sin(x)))
    #],
    ##trig_inverses = [
    ##   @rule "sin-asin" x sin(asin(x)) --> x
    ##   @rule "cos-acos" x cos(acos(x)) --> x
    ##   @rule "tan-atan" x tan(atan(x)) --> x
    ##   @rule "atan-tan" x atan(tan(x)) --> (remainder x (pi))
    ##   @rule "asin-sin" x asin(sin(x)) --> (- (fabs (remainder (+ x (/ (pi) 2)) (* 2 (pi)))) (/ (pi) 2))
    ##   @rule "acos-cos" x acos(cos(x)) --> (fabs (remainder x (* 2 (pi))))
    ##],
    #trig_inverses_simplified = [
    #   @rule "atan-tan-s" x atan(tan(x)) --> x
    #   @rule "asin-sin-s" x asin(sin(x)) --> x
    #   @rule "acos-cos-s" x acos(cos(x)) --> x
    #],
    #trig_reduce_sound = [
    #   @rule "cos-sin-sum" a ((cos(a)*cos(a))+(sin(a)*sin(a))) --> 1
    #   @rule "1-sub-cos" a (1-(cos(a)*cos(a))) --> (sin(a)*sin(a))
    #   @rule "1-sub-sin" a (1-(sin(a)*sin(a))) --> (cos(a)*cos(a))
    #   @rule "-1-add-cos" a ((cos(a)*cos(a))+-1) --> neg((sin(a)*sin(a)))
    #   @rule "-1-add-sin" a ((sin(a)*sin(a))+-1) --> neg((cos(a)*cos(a)))
    #   @rule "sub-1-cos" a ((cos(a)*cos(a))-1) --> neg((sin(a)*sin(a)))
    #   @rule "sub-1-sin" a ((sin(a)*sin(a))-1) --> neg((cos(a)*cos(a)))
    #   @rule "sin-pi/6"  sin((pi/6)) --> 1/2
    #   @rule "sin-pi/4"  sin((pi/4)) --> (sqrt(2)/2)
    #   @rule "sin-pi/3"  sin((pi/3)) --> (sqrt(3)/2)
    #   @rule "sin-pi/2"  sin((pi/2)) --> 1
    #   @rule "sin-pi"  sin(pi) --> 0
    #   @rule "sin-+pi" x sin((x+pi)) --> neg(sin(x))
    #   @rule "sin-+pi/2" x sin((x+(pi/2))) --> cos(x)
    #   @rule "cos-pi/6"  cos((pi/6)) --> (sqrt(3)/2)
    #   @rule "cos-pi/4"  cos((pi/4)) --> (sqrt(2)/2)
    #   @rule "cos-pi/3"  cos((pi/3)) --> 1/2
    #   @rule "cos-pi/2"  cos((pi/2)) --> 0
    #   @rule "cos-pi"  cos(pi) --> -1
    #   @rule "cos-+pi" x cos((x+pi)) --> neg(cos(x))
    #   @rule "cos-+pi/2" x cos((x+(pi/2))) --> neg(sin(x))
    #   @rule "tan-pi/6"  tan((pi/6)) --> (1/sqrt(3))
    #   @rule "tan-pi/4"  tan((pi/4)) --> 1
    #   @rule "tan-pi/3"  tan((pi/3)) --> sqrt(3)
    #   @rule "tan-pi"  tan(pi) --> 0
    #   @rule "tan-+pi" x tan((x+pi)) --> tan(x)
    #   @rule "hang-0p-tan" a (sin(a)/(1+cos(a))) --> tan((a/2))
    #   @rule "hang-0m-tan" a (neg(sin(a))/(1+cos(a))) --> tan((neg(a)/2))
    #   @rule "hang-p0-tan" a ((1-cos(a))/sin(a)) --> tan((a/2))
    #   @rule "hang-m0-tan" a ((1-cos(a))/neg(sin(a))) --> tan((neg(a)/2))
    #   @rule "hang-p-tan" a b ((sin(a)+sin(b))/(cos(a)+cos(b))) --> tan(((a+b)/2))
    #   @rule "hang-m-tan" a b ((sin(a)-sin(b))/(cos(a)+cos(b))) --> tan(((a-b)/2))
    #],
    #trig_reduce = [
    #   @rule "tan-+pi/2" x tan((x+(pi/2))) --> (-1/tan(x))
    #],
    #trig_expand_sound = [
    #   @rule "sin-sum" y x sin((x+y)) --> ((sin(x)*cos(y))+(cos(x)*sin(y)))
    #   @rule "cos-sum" y x cos((x+y)) --> ((cos(x)*cos(y))-(sin(x)*sin(y)))
    #   @rule "tan-sum" y x tan((x+y)) --> ((tan(x)+tan(y))/(1-(tan(x)*tan(y))))
    #   @rule "sin-diff" y x sin((x-y)) --> ((sin(x)*cos(y))-(cos(x)*sin(y)))
    #   @rule "cos-diff" y x cos((x-y)) --> ((cos(x)*cos(y))+(sin(x)*sin(y)))
    #   @rule "sin-2" x sin((2*x)) --> (2*(sin(x)*cos(x)))
    #   @rule "sin-3" x sin((3*x)) --> ((3*sin(x))-(4*(sin(x)^3)))
    #   @rule "2-sin" x (2*(sin(x)*cos(x))) --> sin((2*x))
    #   @rule "3-sin" x ((3*sin(x))-(4*(sin(x)^3))) --> sin((3*x))
    #   @rule "cos-2" x cos((2*x)) --> ((cos(x)*cos(x))-(sin(x)*sin(x)))
    #   @rule "cos-3" x cos((3*x)) --> ((4*(cos(x)^3))-(3*cos(x)))
    #   @rule "2-cos" x ((cos(x)*cos(x))-(sin(x)*sin(x))) --> cos((2*x))
    #   @rule "3-cos" x ((4*(cos(x)^3))-(3*cos(x))) --> cos((3*x))
    #],
    #trig_expand_sound2 = [
    #   @rule "sqr-sin-a" x (sin(x)*sin(x)) --> (1/2-(1/2*cos((2*x))))
    #   @rule "sqr-cos-a" x (cos(x)*cos(x)) --> (1/2+(1/2*cos((2*x))))
    #   @rule "diff-sin" y x (sin(x)-sin(y)) --> (2*(sin(((x-y)/2))*cos(((x+y)/2))))
    #   @rule "diff-cos" y x (cos(x)-cos(y)) --> (-2*(sin(((x-y)/2))*sin(((x+y)/2))))
    #   @rule "sum-sin" y x (sin(x)+sin(y)) --> (2*(sin(((x+y)/2))*cos(((x-y)/2))))
    #   @rule "sum-cos" y x (cos(x)+cos(y)) --> (2*(cos(((x+y)/2))*cos(((x-y)/2))))
    #   @rule "cos-mult" y x (cos(x)*cos(y)) --> ((cos((x+y))+cos((x-y)))/2)
    #   @rule "sin-mult" y x (sin(x)*sin(y)) --> ((cos((x-y))-cos((x+y)))/2)
    #   @rule "sin-cos-mult" y x (sin(x)*cos(y)) --> ((sin((x-y))+sin((x+y)))/2)
    #   @rule "diff-atan" y x (atan(x)-atan(y)) --> ((x-y)atan2(1+(x*y)))
    #   @rule "sum-atan" y x (atan(x)+atan(y)) --> ((x+y)atan2(1-(x*y)))
    #   @rule "tan-quot" x tan(x) --> (sin(x)/cos(x))
    #   @rule "quot-tan" x (sin(x)/cos(x)) --> tan(x)
    #   @rule "tan-2" x tan((2*x)) --> ((2*tan(x))/(1-(tan(x)*tan(x))))
    #   @rule "2-tan" x ((2*tan(x))/(1-(tan(x)*tan(x)))) --> tan((2*x))
    #],
    #trig_expand = [
    #   @rule "tan-hang-p" a b tan(((a+b)/2)) --> ((sin(a)+sin(b))/(cos(a)+cos(b)))
    #   @rule "tan-hang-m" a b tan(((a-b)/2)) --> ((sin(a)-sin(b))/(cos(a)+cos(b)))
    #],
    #atrig_expand = [
    #   @rule "cos-asin" x cos(asin(x)) --> sqrt((1-(x*x)))
    #   @rule "tan-asin" x tan(asin(x)) --> (x/sqrt((1-(x*x))))
    #   @rule "sin-acos" x sin(acos(x)) --> sqrt((1-(x*x)))
    #   @rule "tan-acos" x tan(acos(x)) --> (sqrt((1-(x*x)))/x)
    #   @rule "sin-atan" x sin(atan(x)) --> (x/sqrt((1+(x*x))))
    #   @rule "cos-atan" x cos(atan(x)) --> (1/sqrt((1+(x*x))))
    #   @rule "asin-acos" x asin(x) --> ((pi/2)-acos(x))
    #   @rule "acos-asin" x acos(x) --> ((pi/2)-asin(x))
    #   @rule "asin-neg" x asin(neg(x)) --> neg(asin(x))
    #   @rule "acos-neg" x acos(neg(x)) --> (pi-acos(x))
    #   @rule "atan-neg" x atan(neg(x)) --> neg(atan(x))
    #],
    #htrig_reduce = [
    #   @rule "sinh-def" x sinh(x) --> ((exp(x)-exp(neg(x)))/2)
    #   @rule "cosh-def" x cosh(x) --> ((exp(x)+exp(neg(x)))/2)
    #   @rule "tanh-def-a" x tanh(x) --> ((exp(x)-exp(neg(x)))/(exp(x)+exp(neg(x))))
    #   @rule "tanh-def-b" x tanh(x) --> ((exp((2*x))-1)/(exp((2*x))+1))
    #   @rule "tanh-def-c" x tanh(x) --> ((1-exp((-2*x)))/(1+exp((-2*x))))
    #   @rule "sinh-cosh" x ((cosh(x)*cosh(x))-(sinh(x)*sinh(x))) --> 1
    #   @rule "sinh-+-cosh" x (cosh(x)+sinh(x)) --> exp(x)
    #   @rule "sinh---cosh" x (cosh(x)-sinh(x)) --> exp(neg(x))
    #],
    #htrig_expand_sound = [
    #   @rule "sinh-undef" x (exp(x)-exp(neg(x))) --> (2*sinh(x))
    #   @rule "cosh-undef" x (exp(x)+exp(neg(x))) --> (2*cosh(x))
    #   @rule "tanh-undef" x ((exp(x)-exp(neg(x)))/(exp(x)+exp(neg(x)))) --> tanh(x)
    #   @rule "cosh-sum" y x cosh((x+y)) --> ((cosh(x)*cosh(y))+(sinh(x)*sinh(y)))
    #   @rule "cosh-diff" y x cosh((x-y)) --> ((cosh(x)*cosh(y))-(sinh(x)*sinh(y)))
    #   @rule "cosh-2" x cosh((2*x)) --> ((sinh(x)*sinh(x))+(cosh(x)*cosh(x)))
    #   @rule "cosh-1/2" x cosh((x/2)) --> sqrt(((cosh(x)+1)/2))
    #   @rule "sinh-sum" y x sinh((x+y)) --> ((sinh(x)*cosh(y))+(cosh(x)*sinh(y)))
    #   @rule "sinh-diff" y x sinh((x-y)) --> ((sinh(x)*cosh(y))-(cosh(x)*sinh(y)))
    #   @rule "sinh-2" x sinh((2*x)) --> (2*(sinh(x)*cosh(x)))
    #   @rule "sinh-1/2" x sinh((x/2)) --> (sinh(x)/sqrt((2*(cosh(x)+1))))
    #   @rule "tanh-2" x tanh((2*x)) --> ((2*tanh(x))/(1+(tanh(x)*tanh(x))))
    #   @rule "tanh-1/2" x tanh((x/2)) --> (sinh(x)/(cosh(x)+1))
    #   @rule "sum-sinh" y x (sinh(x)+sinh(y)) --> (2*(sinh(((x+y)/2))*cosh(((x-y)/2))))
    #   @rule "sum-cosh" y x (cosh(x)+cosh(y)) --> (2*(cosh(((x+y)/2))*cosh(((x-y)/2))))
    #   @rule "diff-sinh" y x (sinh(x)-sinh(y)) --> (2*(cosh(((x+y)/2))*sinh(((x-y)/2))))
    #   @rule "diff-cosh" y x (cosh(x)-cosh(y)) --> (2*(sinh(((x+y)/2))*sinh(((x-y)/2))))
    #   @rule "tanh-sum" y x tanh((x+y)) --> ((tanh(x)+tanh(y))/(1+(tanh(x)*tanh(y))))
    #],
    #htrig_expand = [
    #   @rule "tanh-1/2*" x tanh((x/2)) --> ((cosh(x)-1)/sinh(x))
    #],
    #htrig_expand_fp_safe = [
    #   @rule "sinh-neg" x sinh(neg(x)) --> neg(sinh(x))
    #   @rule "sinh-0"  sinh(0) --> 0
    #   @rule "cosh-neg" x cosh(neg(x)) --> cosh(x)
    #   @rule "cosh-0"  cosh(0) --> 1
    #],
    #ahtrig_expand_sound = [
    #   @rule "asinh-def" x asinh(x) --> log((x+sqrt(((x*x)+1))))
    #   @rule "acosh-def" x acosh(x) --> log((x+sqrt(((x*x)-1))))
    #   @rule "atanh-def" x atanh(x) --> (log(((1+x)/(1-x)))/2)
    #   @rule "sinh-asinh" x sinh(asinh(x)) --> x
    #   @rule "sinh-acosh" x sinh(acosh(x)) --> sqrt(((x*x)-1))
    #   @rule "sinh-atanh" x sinh(atanh(x)) --> (x/sqrt((1-(x*x))))
    #   @rule "cosh-asinh" x cosh(asinh(x)) --> sqrt(((x*x)+1))
    #   @rule "cosh-acosh" x cosh(acosh(x)) --> x
    #   @rule "cosh-atanh" x cosh(atanh(x)) --> (1/sqrt((1-(x*x))))
    #   @rule "tanh-asinh" x tanh(asinh(x)) --> (x/sqrt((1+(x*x))))
    #   @rule "tanh-acosh" x tanh(acosh(x)) --> (sqrt(((x*x)-1))/x)
    #   @rule "tanh-atanh" x tanh(atanh(x)) --> x
    #],
    #ahtrig_expand = [
    #   @rule "asinh-2" x acosh(((2*(x*x))+1)) --> (2*asinh(x))
    #   @rule "acosh-2" x acosh(((2*(x*x))-1)) --> (2*acosh(x))
    #],
    #compare_reduce = [
    #   @rule "lt-same" x (x<x) --> false
    #   @rule "gt-same" x (x>x) --> false
    #   @rule "lte-same" x (x<=x) --> true
    #   @rule "gte-same" x (x>=x) --> true
    #   @rule "not-lt" y x not((x<y)) --> (x>=y)
    #   @rule "not-gt" y x not((x>y)) --> (x<=y)
    #   @rule "not-lte" y x not((x<=y)) --> (x>y)
    #   @rule "not-gte" y x not((x>=y)) --> (x<y)
    #],
#branch_reduce = [
#   @rule "if-true" y x (if (true) x y) --> x
#   @rule "if-false" y x (if (false) x y) --> y
#   @rule "if-same" x a (if a x x) --> x
#   @rule "if-not" y x a (if (not a) x y) --> (if a y x)
#   @rule "if-if-or" y x a b (if a x (if b x y)) --> (if (or a b) x y)
#   @rule "if-if-or-not" y x a b (if a x (if b y x)) --> (if (or a (not b)) x y)
#   @rule "if-if-and" y x a b (if a (if b x y) y) --> (if (and a b) x y)
#   @rule "if-if-and-not" y x a b (if a (if b y x) y) --> (if (and a (not b)) x y)
#],

)


REWRITE_THEORY = convert(Vector{RewriteRule}, reduce(∪, theories))
SIMPLIFY_THEORY = convert(Vector{RewriteRule}, reduce(∪, [
   theories.commutativity,
   theories.associativity,
   theories.counting,
   theories.distributivity,
   theories.distributivity_fp_safe,
   theories.cancel_sign_fp_safe,
   theories.difference_of_squares_canonicalize,
   theories.id_reduce,
   theories.id_reduce_fp_safe,
   theories.id_reduce_fp_safe_nan,
   theories.nan_transform_fp_safe,
   theories.squares_reduce,
   theories.squares_transform,
   theories.pow_canonicalize,
   theories.fractions_distribute,
   theories.fractions_transform,
]))
