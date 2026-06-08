# Smoke tests for the public types/accessors. The data-cleaning and summary
# operations have their own, more thorough suite; this file just checks that the
# package loads and the `Table` accessors behave.
include(joinpath(@__DIR__, "..", "src", "CrimeAnalytics.jl"))
using .CrimeAnalytics
using Test

@testset "Table accessors" begin
    t = Table(["a", "b"], Dict("a" => Cell[1, 2, 3], "b" => Cell["x", "y", "z"]))
    @test nrows(t) == 3
    @test ncols(t) == 2
    @test colnames(t) == ["a", "b"]
    @test getcolumn(t, "a") == [1, 2, 3]
    @test_throws KeyError getcolumn(t, "missing")

    empty = Table(String[], Dict{String,Vector{Cell}}())
    @test nrows(empty) == 0
    @test ncols(empty) == 0
end
