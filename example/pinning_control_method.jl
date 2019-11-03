# This file includes an example to apply pinning control method for full synchronization of networks.

using LightGraphs
using GraphPlot
using LinearAlgebra
using DifferentialEquations
using Plots
using Distributed

# Define node dynamics
function lorenz(dx, x, sigma=10, beta=8/3, rho=28)
    dx[1] = sigma * (x[2] - x[1])
    dx[2] = x[1] * (rho - x[3]) - x[2]
    dx[3] = x[1] * x[2] - beta * x[3]
end

function chen(dx, x, a=35, b=3, c=28)
    dx[1] = a * (x[2] - x[1])
    dx[2] = (c - a) * x[1] + c * x[2] - x[1] * x[3]
    dx[3] = x[1] * x[2] - b * x[3]
end

# Determine a network topology
n = 20
δ = 0.4
d = 3
l = floor(Int, δ * n)
r = n - l
f = chen
# graph = star_graph(n)
graph = static_scale_free(n, 100, 5)
P = diagm([1, 2, 1])
Ξ = -1 * collect(laplacian_matrix(graph))
Ξ11, Ξ12, Ξ21, Ξ22 = Ξ[1 : l, 1 : l], Ξ[1 : l, l + 1 : n], Ξ[l + 1 : n, 1 : l], Ξ[l + 1 : n, l + 1 : n] 

# Determine θ
θ = 31.

# Compute coupling strength threshold
ϵth = θ / abs(maximum(eigvals(Ξ22)))
ϵ = 1.1ϵth

# Compute control gain threshold
Ω = θ * diagm(ones(l)) + ϵ * Ξ11 - ϵ^2 * Ξ12 * inv(θ * diagm(ones(r)) + ϵ * Ξ22) * Ξ12'
αth = maximum(eigvals(Ω)) / ϵ
α = 0.01*αth

A = diagm(vcat([α for i = 1 : l], zeros(r)))

# Define coupled network dynamics
function statefunc(dx, x, u, t, f=f, Ξ=Ξ, P=P, A=A, ϵ=ϵ)
    n = size(Ξ, 1)
    d = size(P, 1)
    for i = 1 : n + 1
        f(view(dx, (i - 1) * d + 1 : i * d), view(x, (i - 1) * d + 1 : i * d)) 
    end
    dx[1 * d + 1 : end] .+= ϵ * kron(Ξ, P) * x[1 * d + 1 : end]
    dx[1 * d + 1 : end] .-= ϵ * kron(A, P) * (x[1 * d + 1 : end] - repeat(x[1:3], n))
end

# Simulation network
tspan = (0., 20.)
x0 = rand((n + 1) * d)
sol = solve(ODEProblem(statefunc, x0, tspan))
states = collect(hcat(sol.u...)')
t = collect(vcat(sol.t...))

# Plot the results
p1 = plot(t, states[:,1])
p2 = plot(states[:,1], states[:,2])
p3 = plot()
foreach(i -> plot!(t, states[:, 1] - states[:, (i - 1) * d + 1], label=string(1) * "-" * string(i)), 2 : n)
p4 = plot()
foreach(i -> plot!(t, states[:, 2] - states[:, (i - 1) * d + 2], label=string(1) * "-" * string(i)), 2 : n)
p5 = plot()
foreach(i -> plot!(t, states[:, 3] - states[:, (i - 1) * d + 3], label=string(1) * "-" * string(i)), 2 : n)
display(gplot(graph, nodelabel=1:nv(graph)))
display(plot(p1, p2, p3, p4, p5))
