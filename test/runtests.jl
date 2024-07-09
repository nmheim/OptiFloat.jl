using Test
using TestItems
using TestItemRunner

@testitem "sample.jl" begin
    include("sample.jl")
end

@testitem "evaluate.jl" begin
    include("evaluate.jl")
end

@testitem "error.jl" begin
    include("error.jl")
end
