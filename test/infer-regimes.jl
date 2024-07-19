using DynamicExpressions
using IntervalArithmetic: sup, inf
using OptiFloat: Candidate, infer_regimes, biterror, regimes, Regime, PiecewiseRegime, regime

T = Float64
x_dummy = parse_expression(:(x); variable_names=["x"])
y_dummy = parse_expression(:(y); variable_names=["y"])
z_dummy = parse_expression(:(z); variable_names=["z"])

@testset "1d regime inference" begin
    x_errors = T[1, 1, 0, 0, 1, 1] .* 3
    y_errors = T[0, 0, 1, 1, 1, 1] .* 3
    z_errors = T[1, 1, 1, 1, 0, 0] .* 3

    cx = Candidate(x_dummy, x_dummy, Ref(false), x_errors, identity)
    cy = Candidate(y_dummy, y_dummy, Ref(false), y_errors, identity)
    cz = Candidate(z_dummy, z_dummy, Ref(false), z_errors, identity)

    # joining regimes
    rx1 = Regime(cx, -Inf, -0.5, 1, Bool[1, 0, 0, 0, 0, 0])
    rx2 = Regime(cx, -0.5, 0.5, 1, Bool[0, 1, 0, 0, 0, 0])
    pr = join(rx1, rx2)
    @test pr.regs[end].error_mask == Bool[1, 1, 0, 0, 0, 0]
    @test sup(pr) == 0.5
    @test inf(pr) == -Inf

    # overlapping regimes
    rx3 = Regime(cx, 0.0, 1.5, 1, Bool[0, 1, 1, 0, 0, 0])
    pr = join(join(rx1, rx2), rx3)
    @test pr.regs[end].error_mask == Bool[1, 1, 1, 0, 0, 0]
    @test sup(pr) == 1.5
    @test inf(pr) == -Inf

    # joining piecewise regimes
    ry1 = Regime(cy, -1.5, -0.5, 1, Bool[1, 0, 0, 0, 0, 0])
    pr = reduce(join, [ry1, rx2, rx3])
    @test pr.regs[1].error_mask == Bool[1, 0, 0, 0, 0, 0]
    @test pr.regs[2].error_mask == Bool[0, 1, 1, 0, 0, 0]

    points = T[-2 -1 0 1 2 3]
    splits = T[-1.5, -0.5, 0.5, 1.5, 2.5]
    rx = Regime(cx, -0.5, 1.5, 1, Bool[0, 0, 1, 1, 0, 0])
    ry = Regime(cy, -Inf, -0.5, 1, Bool[1, 1, 0, 0, 0, 0])
    rz = Regime(cz, 1.5, Inf, 1, Bool[0, 0, 0, 0, 1, 1])
    pr = infer_regimes([cx, cy, cz], 1, points; splits=splits)
    @test pr == join(join(ry, rx), rz)
end

@testset "2d regime inference" begin
    # error grids 4x5
    #! format: off
    e1_errors = T[
    #  -2 -1  0  1  2
        0, 0, 1, 1, 1, # 1
        0, 0, 1, 1, 1, # 2
        0, 0, 1, 1, 1, # 3
        0, 0, 1, 1, 1, # 4
    ] .* 10

    #! format: off
    e2_errors = T[
    #  -2 -1  0  1  2
        1, 1, 0, 0, 0, # 1
        1, 1, 0, 0, 0, # 2
        1, 1, 0, 0, 0, # 3
        1, 1, 0, 0, 0, # 4
    ] .* 10

    # dummy candidates; only errors are important
    points = convert(Matrix{T}, mapreduce(collect, hcat, Iterators.product(-2:2, 1:4)))
    c1 = Candidate(x_dummy, x_dummy, Ref(false), e1_errors, identity)
    c2 = Candidate(y_dummy, y_dummy, Ref(false), e2_errors, identity)

    splits = [-1.5, -0.5, 0.5, 1.5]
    feature = 1
    pr1 = infer_regimes([c1, c2], feature, points; splits=splits)
    @test pr1 == join(regime(c1, points, -Inf, -0.5, 1), regime(c2, points, -0.5, Inf, 1))
end
