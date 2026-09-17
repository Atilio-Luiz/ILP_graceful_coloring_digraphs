# Graceful Coloring of Simple Digraphs — ILP Formulation

This repository contains an **Integer Linear Programming (ILP) formulation** for the **Graceful Coloring Problem of simple digraphs**.

The implementation is written in **Julia** using [JuMP](https://jump.dev/) and the open-source **HiGHS** mixed-integer optimization solver.

**Author:** Atílio G. Luiz  
**Date:** September 2026

## Problem Description

Let \(D=(V,A)\) be a simple digraph. A graceful \(k\)-coloring is a vertex coloring
\[
f:V(D)\rightarrow\mathbb{Z}_k
\]
such that each arc \(e=(u,v)\) receives the induced color
\[
g(e)=(f(v)-f(u))\pmod{k},
\]
with \(g(e)\in\{1,\ldots,k-1\}\), and adjacent arcs receive distinct colors. Two arcs are adjacent when they share a common endpoint.

The objective is to minimize \(k\).

## Dependencies

- Julia 1.10 or later
- JuMP.jl
- HiGHS.jl
- Graphs.jl
- Printf (Julia standard library)

HiGHS is open source and does not require a commercial license.

## Installation

Clone the repository and activate its Julia environment:

```bash
git clone https://github.com/YOUR_USERNAME/graceful-coloring-digraphs.git
cd graceful-coloring-digraphs
julia --project=.
```

Instantiate the dependencies:

```julia
using Pkg
Pkg.instantiate()
```

The project environment is described by `Project.toml`. Running `Pkg.instantiate()` creates a `Manifest.toml` with the resolved package versions. For strict computational reproducibility, the generated `Manifest.toml` may be committed to the repository.

## Running the Example

Run:

```bash
julia --project=. examples/example.jl
```

The example constructs a five-vertex simple digraph and solves its graceful coloring problem.

## Running the Tests

Run:

```bash
julia --project=. test/runtests.jl
```

or:

```julia
using Pkg
Pkg.test()
```

## Repository Structure

```text
graceful-coloring-digraphs/
│
├── src/
│   └── GracefulColoring.jl
│
├── examples/
│   └── example.jl
│
├── test/
│   └── runtests.jl
│
├── Project.toml
├── LICENSE
└── README.md
```

## Formulation

For every vertex \(v\), the model uses an integer variable \(x_v\) for its color.

For every arc \(e=(u,v)\), an integer variable \(g_e\) represents its induced color. Binary variables are used to linearize the modular difference and to enforce distinct colors on adjacent arcs.

The formulation includes the strengthening constraint

\[
k\geq\Delta(D)+1,
\]

where

\[
\Delta(D)=\max_{v\in V(D)}\{d^-(v)+d^+(v)\}.
\]

It also fixes one reference vertex to color 0 to break color-translation symmetry.

## Big-M

The implementation uses

\[
M=\left\lceil\frac{3}{2}\Delta(D)^2\right\rceil+1.
\]

Here \(\Delta(D)\) denotes the maximum total directed degree \(d^-(v)+d^+(v)\).

## Using the Solver on Another Digraph

The main function is:

```julia
graceful_coloring_ILP(D; verbose=false)
```

where `D` is a `Graphs.SimpleDiGraph`.

Example:

```julia
D = SimpleDiGraph(6)

add_edge!(D, 1, 2)
add_edge!(D, 1, 3)
add_edge!(D, 2, 4)
add_edge!(D, 3, 4)
add_edge!(D, 4, 5)
add_edge!(D, 5, 6)

result = graceful_coloring_ILP(D; verbose=true)

println("Minimum number of colors: ", result.k)
```

The function returns a named tuple containing:

- `model`: the JuMP model;
- `status`: the solver termination status;
- `primal_status`: the primal status;
- `k`: the objective value when a solution is available;
- `vertex_colors`: the vertex coloring;
- `arc_colors`: the induced arc coloring.

## Solver

The default optimizer is:

```julia
model = Model(HiGHS.Optimizer)
```

The formulation is implemented using standard JuMP constructs and can, in principle, be used with other JuMP-compatible MILP solvers.

## Citation

If you use this implementation in academic work, please cite the associated paper:

```bibtex
@article{Luiz2026GracefulColoringDigraphs,
  author  = {Atílio G. Luiz},
  title   = {Graceful Coloring of Digraphs},
  journal = {...},
  year    = {2026}
}
```

Update the citation information once the associated paper has been published.

## License

This project is released under the MIT License. See `LICENSE`.

## Author

**Atílio G. Luiz**  
Federal University of Ceará (UFC), Campus Quixadá, Brazil
