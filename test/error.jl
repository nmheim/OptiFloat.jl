using DynamicExpressions: Node, parse_expression
using OptiFloat:
    Candidate,
    all_subexpressions,
    ulpdistance,
    biterror,
    local_biterror,
    local_biterrors,
    logsample,
    logsample

@testset "Biterror" begin
    @test ulpdistance(Float16(0), Float16(1)) == 15360

    T = Float16
    dexpr = parse_expression(
        :(x + 1 - x); binary_operators=[+, -], variable_names=["x"], node_type=Node{T}
    )

    x = T(5e3)
    # first 14 significant bits should be incorrect
    @test round(Int, biterror(dexpr, [x])) == 14
    @test round.(Int, biterror(dexpr, reshape([x], 1, 1); accum=identity)) == [14]
end

@testset "Local biterror dynamic expression" begin
    T = Float16
    kws = (;
        binary_operators=[+, -], unary_operators=[sqrt], variable_names=["x1"], node_type=Node{T}
    )
    dexpr = parse_expression(:(x1 + 1 - x1); kws...)

    x = reshape(T[5e3 for _ in 1:100], 1, 100)
    e = local_biterror(dexpr, x)
    @test e ≈ T(log2(ulpdistance(T(0), T(1))))

    d = local_biterrors(dexpr, x)
    @test d isa Dict{Node{T},T}

    a = Node(T; feature=1)
    target = Dict(
        Node{T}(; val=1.0) => 0,
        a + 1 => 0,
        (a + 1) - a => round(Int, log2(ulpdistance(T(0), T(1)))),
        a => 0,
    )
    @test target == Dict(k=>round(Int,v) for (k,v) in d)

    # dexpr = parse_expression(:(sqrt(x1 + 1) - sqrt(x1)); kws...)
    # points = logsample(dexpr, T, arity, 8000)
    # local_biterrors(dexpr, points)
    # FIXME: Supposition.jl
    # check that error of any expression is >= 0
end

@testset "logsample" begin
    T = Float16
    orig_expr = :((-b - sqrt(b^2 - 4 * c)) / (2 * c))
    kws = (;
        binary_operators=[-, ^, /, *, +],
        unary_operators=[-, sqrt],
        node_type=Node{T},
        variable_names=["b", "c"],
    )
    dexpr = parse_expression(orig_expr; kws...)
    points = logsample(dexpr, T, 2, 8000; eval_exact=false)
    local_biterrors(dexpr, points)
    c = Candidate(dexpr, dexpr, points)
    @test isfinite(sum(c.errors))
end
