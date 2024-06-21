function evaluate_exact(f, args::Union{<:Number,Int}...; init_precision::Int=53, max_precision::Int=1500)
    # compute interval for higher precision
    precision_interval = setprecision(init_precision) do
        intervals = interval.(BigFloat.(args))
        f(intervals...)
    end

    # check if we found an interval that only contains one number 𝑅𝑝(𝑦1) = 𝑦∗ = 𝑅𝑝(𝑦2)
    new_precision = init_precision * 2
    if isthin(precision_interval) || new_precision > max_precision
        setprecision(init_precision) do
            mid(precision_interval)
        end
    else
        evaluate_exact(f, args..., init_precision=new_precision, max_precision=max_precision)
    end
end

function evaluate_exact(expr::Expr, point::Union{<:Point,<:Batch}; kw...)
    g = lambdify(expr, keys(point)...)
    evaluate_exact.(g, values(point)...; kw...)
end
evaluate_exact(x::Symbol, p::Union{<:Point,<:Batch}; kw...) = p[x]
evaluate_exact(x::Number, p::Union{<:Point,<:Batch}; kw...) = x

Base.isfinite(x::Interval) = isbounded(x)
function evaluate_exact(expr::Node{Interval{BigFloat}}, ops::OperatorEnum, X::Matrix{Interval{BigFloat}}; init_precision::Int=53, max_precision::Int=1500)
    precision_intervals = setprecision(init_precision) do
        expr(X, ops)
    end

    # check if we found an interval that only contains one number 𝑅𝑝(𝑦1) = 𝑦∗ = 𝑅𝑝(𝑦2)
    new_precision = init_precision * 2
    if all(isthin.(precision_intervals)) || new_precision > max_precision
        setprecision(init_precision) do
            mid.(precision_intervals)
        end
    else
        evaluate_exact(expr, ops, X, init_precision=new_precision, max_precision=max_precision)
    end
end

function evaluate_exact(expr::Node{T}, ops::OperatorEnum, X::Matrix{T}; kw...) where T
    evaluate_exact(
        convert(Node{Interval{BigFloat}},expr),
        ops,
        convert(Matrix{Interval{BigFloat}},X);
        kw...
    )
end

evaluate(expr, point::Point) = lambdify(expr, keys(point)...)(values(point)...)
