using Metatheory
using Metatheory.Rewriters


function simplify(expr, theory=SIMPLIFY_THEORY; steps=1, timeout=10)
    for _ in 1:steps
        g = EGraph(expr)
        p = SaturationParams(;
            timeout=timeout,
            scheduler=Schedulers.BackoffScheduler,
            schedulerparams=(match_limit=6000, ban_length=5),
            timer=false,
        )
        saturate!(g, theory, p)
        expr = extract!(g, astsize)
    end
    expr
end


## Rewrite expressions to include Expr(:alternative, original, op, args...)

struct AlternativeRewriter{F}
    rw::F
end

alternative_expr(expr::Expr, new::Expr) = Expr(:alternative, expr, operation(new), arguments(new)...)

function (cr::AlternativeRewriter)(expr)
    x = cr.rw(expr)
    isnothing(x) ? expr : alternative_expr(expr, x)
end

alternatives(expr, theory) = [expr]
function alternatives(expr::Expr, theory=SIMPLIFY_THEORY)
    if head(expr)==:alternative
        orig = expr.args[1]
        op = expr.args[2]
        args = expr.args[3:end]
        argss = [alternatives(arg, theory) for arg in args]

        # only simplify children of current node
        #@info "before" argss
        argss = map(argss) do args
            map(a -> simplify(a,theory), args)
        end
        #@info "after" argss theory

        [orig; vec([Expr(:call, op, args...) for args in Iterators.product(argss...)])]
    else
        argss = [alternatives(arg, theory) for arg in arguments(expr)]
        argss = Iterators.product(argss...)
        [maketerm(typeof(expr), head(expr), [operation(expr); args...], nothing) for args in argss] |> vec
    end
end

function rewrite_once(expr; rewrite_theory=REWRITE_THEORY, simplify_theory=SIMPLIFY_THEORY)
    rws = unique(map(r -> AlternativeRewriter(r)(expr), rewrite_theory))
    mapreduce(e -> alternatives(e,simplify_theory), vcat, rws) |> unique
end

function recursive_rewrite(expr::E; rewrite_theory=REWRITE_THEORY, simplify_theory=SIMPLIFY_THEORY, depth=3) where E
    if iscall(expr) && depth > 0
        op = operation(expr)
        # rewrite all arguments to op
        argss = [recursive_rewrite(a; rewrite_theory=rewrite_theory, simplify_theory=simplify_theory, depth=depth - 1) for a in arguments(expr)]
        @info "rec" expr argss
        # all combinations of rewritten arguments
        argss = Iterators.product(argss...)
        # rewrite op itself
        rwo = if expr isa Expr  # FIXME: uglyyyy
            #[rewrite_once(maketerm(E, :call, (op, args...), nothing), theory) for args in argss]
            map(argss) do args
                curr = maketerm(E, :call, [op; args...], nothing)
                rws = rewrite_once(curr, rewrite_theory=rewrite_theory, simplify_theory=simplify_theory)
                @info "make" curr rws
                rws
            end
        else
            #[rewrite_once(maketerm(E, op, collect(args), nothing), theory) for args in argss]
            error("not implemented")
        end
        reduce(vcat, rwo)
    else
        [expr]
    end |> unique
end
recursive_rewrite(x::Union{Symbol,Number}, theory, depth=3) = [x]
