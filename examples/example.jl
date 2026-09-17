# Example: Graceful coloring of a simple digraph

using Pkg
Pkg.activate(joinpath(@__DIR__, ".."))

include(joinpath(@__DIR__, "..", "src", "GracefulColoring.jl"))
using .GracefulColoring

using Graphs

D = SimpleDiGraph(5)

add_edge!(D, 2, 1)
add_edge!(D, 2, 5)
add_edge!(D, 3, 1)
add_edge!(D, 3, 2)
add_edge!(D, 3, 4)
add_edge!(D, 4, 1)
add_edge!(D, 5, 1)
add_edge!(D, 5, 2)
add_edge!(D, 5, 3)
add_edge!(D, 5, 4)

result = graceful_coloring_ILP(D; verbose=true)

println("\nMinimum number of colors: ", result.k)
