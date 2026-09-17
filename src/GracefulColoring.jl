module GracefulColoring

using JuMP
using HiGHS
using Graphs
using Printf
import MathOptInterface as MOI

export graceful_coloring_ILP

"""
    graceful_coloring_ILP(D::SimpleDiGraph; verbose=false)

Solve the graceful coloring problem of the simple digraph `D` by
integer linear programming.

Returns a named tuple containing the optimization status, primal status,
and the solution values when a feasible solution is available.
"""
function graceful_coloring_ILP(D::SimpleDiGraph; verbose::Bool=false)

    VERTICES = collect(vertices(D))
    ARCS = [(src(e), dst(e)) for e in edges(D)]

    isempty(VERTICES) && error("The digraph must contain at least one vertex.")

    # Total directed degree d⁻(v) + d⁺(v).
    deg_in  = Dict(v => 0 for v in VERTICES)
    deg_out = Dict(v => 0 for v in VERTICES)

    for (i, j) in ARCS
        deg_out[i] += 1
        deg_in[j]  += 1
    end

    Δ = maximum(deg_in[v] + deg_out[v] for v in VERTICES)
    M = Int(ceil(3 / 2 * Δ^2) + 1)

    # Construct a list of pairs of adjacent arcs.
    # Two arcs are adjacent if they share a common endpoint.
    adjacent_arcs = Set{Tuple{Tuple{Int,Int},Tuple{Int,Int}}}()

    for u in VERTICES
        incident = Tuple{Int,Int}[]

        append!(incident, ((v, u) for v in inneighbors(D, u)))
        append!(incident, ((u, w) for w in outneighbors(D, u)))

        for i in 1:(length(incident) - 1)
            for j in (i + 1):length(incident)
                e, f = incident[i], incident[j]
                push!(adjacent_arcs, e < f ? (e, f) : (f, e))
            end
        end
    end

    # =======================================================
    # JuMP model using HiGHS
    # =======================================================
    model = Model(HiGHS.Optimizer)

    # =======================================================
    # Variables
    # =======================================================

    # k: number of colors.
    @variable(model, 0 <= k <= M, Int)

    # x[v]: vertex color.
    @variable(model, 0 <= x[v in VERTICES] <= M - 1, Int)

    # g[e]: arc color.
    @variable(model, 1 <= g[e in ARCS] <= M - 1, Int)

    # b[e]: 1 if x_dst - x_src is negative, 0 otherwise.
    @variable(model, b[e in ARCS], Bin)

    # w[e] = b[e] * k.
    @variable(model, 0 <= w[e in ARCS] <= M, Int)

    # s[e,e']: linearization variable for g[e] != g[e'].
    @variable(model, s[pair in adjacent_arcs], Bin)

    # =======================================================
    # Objective
    # =======================================================
    @objective(model, Min, k)

    # =======================================================
    # Constraints
    # =======================================================

    # R1) Vertex colors belong to {0,...,k-1}.
    for v in VERTICES
        @constraint(model, x[v] <= k - 1)
    end

    # R2) Arc colors belong to {1,...,k-1}.
    for e in ARCS
        @constraint(model, g[e] <= k - 1)
    end

    # R3) Forces x_dst != x_src for every arc.
    for e in ARCS
        @constraint(model, x[e[2]] - x[e[1]] >= 1 - M * b[e])
        @constraint(model, x[e[2]] - x[e[1]] <= -1 + M * (1 - b[e]))
    end

    # R4) Adjacent arcs must have distinct colors.
    for (e1, e2) in adjacent_arcs
        @constraint(model, g[e1] - g[e2] >= 1 - M * s[(e1, e2)])
        @constraint(model, g[e1] - g[e2] <= -1 + M * (1 - s[(e1, e2)]))
    end

    # R5.1) g_e = x_dst - x_src + w_e.
    for e in ARCS
        @constraint(model, g[e] == x[e[2]] - x[e[1]] + w[e])
    end

    # R5.2-R5.4) w_e = b_e * k.
    for e in ARCS
        @constraint(model, w[e] <= k)
        @constraint(model, w[e] <= M * b[e])
        @constraint(model, w[e] >= k - M * (1 - b[e]))
    end

    # Strengthening: k >= Δ(D) + 1.
    @constraint(model, k >= Δ + 1)

    # Symmetry breaking: fix one reference vertex to color 0.
    @constraint(model, x[VERTICES[1]] == 0)

    # =======================================================
    # Solve
    # =======================================================
    optimize!(model)

    termination = termination_status(model)
    primal = primal_status(model)

    println("Termination status: ", termination)
    println("Primal status: ", primal)

    feasible = termination in (
        MOI.OPTIMAL,
        MOI.LOCALLY_SOLVED,
        MOI.FEASIBLE_POINT,
        MOI.TIME_LIMIT,
    ) && has_values(model)

    if !feasible
        println("No feasible solution was found. Status: ", termination)
        return (
            model=model,
            status=termination,
            primal_status=primal,
            k=nothing,
            vertex_colors=nothing,
            arc_colors=nothing,
        )
    end

    k_val = Int(round(value(k)))
    @printf("Objective value (k) = %d\n", k_val)

    vertex_colors = Dict(v => Int(round(value(x[v]))) for v in VERTICES)
    arc_colors = Dict(e => Int(round(value(g[e]))) for e in ARCS)

    if verbose
        println("Vertex colors:")
        for v in VERTICES
            println("  x[$v] = ", vertex_colors[v])
        end

        println("Arc colors g_e:")
        for e in ARCS
            println("  arc=$e --> g[$e] = ", arc_colors[e])
        end

        println("b_e values (indicate whether x_dst < x_src):")
        for e in ARCS
            println("  b[$e] = ", Int(round(value(b[e]))))
        end
    end

    return (
        model=model,
        status=termination,
        primal_status=primal,
        k=k_val,
        vertex_colors=vertex_colors,
        arc_colors=arc_colors,
    )
end

end # module GracefulColoring
