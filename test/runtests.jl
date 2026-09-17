using Test
using Pkg
using Graphs
import MathOptInterface as MOI

Pkg.activate(joinpath(@__DIR__, ".."))

include(joinpath(@__DIR__, "..", "src", "GracefulColoring.jl"))
using .GracefulColoring

@testset "Graceful coloring ILP" begin
    D = SimpleDiGraph(3)
    add_edge!(D, 1, 2)
    add_edge!(D, 2, 3)
    add_edge!(D, 3, 1)

    result = graceful_coloring_ILP(D)

    @test result.k !== nothing
    @test result.status == MOI.OPTIMAL
    @test length(result.vertex_colors) == 3
    @test length(result.arc_colors) == 3
end
