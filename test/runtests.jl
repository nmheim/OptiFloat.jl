using Test
using TestItems
using TestItemRunner

@testitem "terminferface.jl" begin
    include("terminferface.jl")
end

@testitem "rewrite.jl" begin
    include("rewrite.jl")
end

@testitem "sample.jl" begin
    include("sample.jl")
end

@testitem "evaluate.jl" begin
    include("evaluate.jl")
end

@testitem "error.jl" begin
    include("error.jl")
end
