# This file includes an example to apply pinning control method for full synchronization of networks.

using LightGraphs
using GraphPlot
using LinearAlgebra
using DifferentialEquations
using Plots
using BlockArrays

# Define node dynamics
function lu(dx, x, sigma=36, beta=3, rho=20)
    dx[1] = sigma * (x[2] - x[1])
    dx[2] = rho * x[2] - x[1] * x[3]
    dx[3] = x[1] * x[2] - beta * x[3]
end

# Define passivity index.
P = diagm([1, 1, 1])
θ = 37.8

# Define coupling strength
ϵ = 80

# Determine a network topology
n = 11
l = 3
d = 3
m = 5 
f = lu
Ξ = BlockArray([
    0 0 0 0 0 0 0 0 0 0 0;
    0 -2 0 0 0 0 0 0 1 0 1;
    0 0 -1 0 0 0 0 0 0 0 1;
    0 0 0 0 0 0 0 0 0 0 0;
    0 0 0 0 0 0 0 0 0 0 0;
    0 0 1 0 0 -1 0 0 0 0 0;
    0 0 1 1 0 0 -2 0 0 0 0;
    1 1 0 0 0 0 0 -2 0 0 0;
    0 0 0 0 0 0 0 0 -1 1 0;
    0 0 0 0 1 0 0 0 0 -1 0;
    1 0 0 0 0 0 0 0 0 0 -1;
    ], [m, n - m], [m, n - m])
Γ = θ * diagm(ones(n)) + ϵ / 2 * (Ξ + Ξ')
Γ11 = getblock(Γ, 1, 1)
Γ12 = getblock(Γ, 1, 2)
Γ22 = getblock(Γ, 2, 2)
α = 1 / ϵ * maximum(eigvals(Γ11 - Γ12 * inv(Γ22) * Γ12'))  # Control strength

E = BlockArray([zeros(l, l) zeros(l, n); zeros(n, l) Ξ], [l, m, n - m], [l, m, n - m])
F = BlockArray(zeros(size(E)), [l, m, n - m], [l, m, n - m])
F21 = getblock(F, 2, 1)
F21[1, 1] = -α
F21[2, 1] = -α
F21[3, 2] = -α
F21[4, 2] = -α
F21[5, 3] = -α
F22 = getblock(F, 2, 2)
for i = 1 : m 
    F22[i, i] = α
end
G = BlockArray(zeros(size(E)), [l, m, n - m], [l, m, n - m])
G21 = getblock(G, 2, 1)
G21[2, 1] = Ξ[2, 1] + Ξ[2, 2] + Ξ[2, 8] + Ξ[2, 11] 
G21[2, 2] = Ξ[2, 3] + Ξ[2, 4] + Ξ[2, 6] + Ξ[2,7] 
G21[2, 3] = Ξ[2, 5] + Ξ[2, 9] + Ξ[2, 10] 
G21[3, 1] = Ξ[3, 1] + Ξ[3, 2] + Ξ[3, 8] + Ξ[3, 11] 
G21[3, 2] = Ξ[3, 3] + Ξ[3, 4] + Ξ[3, 6] + Ξ[3,7] 
G21[3, 3] = Ξ[3, 5] + Ξ[3, 9] + Ξ[3, 10] 

# M = ϵ * kron(E, P)

# # Define coupled network dynamics
M = ϵ * kron(E - F - G, P)

# f = lu
# n = 14 
# d = 3
function statefunc(dx, x, u, t, f=f, M = M, ni=n+l, di=d)
# function statefunc(dx, x, u, t, f=f, n=n, d=d)
    # Individual evolution
    for i = 1 : ni
        f(view(dx, (i - 1) * di + 1 : i * di), view(x, (i - 1) * di + 1 : i * di)) 
    end
    dx .+= M * x
end

# Simulation network
tspan = (0., 100.)
# x0 = rand(n  * d)
x0 = rand((n + l) * d)
@info "Solving network..."
sol = solve(ODEProblem(statefunc, x0, tspan), saveat=0.005)
@info "Done..."
states = collect(hcat(sol.u...)')
t = collect(vcat(sol.t...))

# Plot the results
p1 = plot(t, states[:,1], label="")
p2 = plot(states[:,1], states[:,2], label="")
p3 = plot()
for i in [1, 2, 8, 11]
    plot!(states[:, 1] - states[:, (i + l - 1) * d + 1], label="1-$i")
end
p4 = plot()
for i in [3, 4, 6, 7]
    plot!(states[:, 4] - states[:, (i + l - 1) * d + 1], label="2-$i")
end
p5 = plot()
for i in [5, 9, 10]
    plot!(states[:, 7] - states[:, (i + l - 1) * d + 1], label="3-$i")
end
p6 = plot()
for i in [3, 5]
    plot!(states[:, 1] - states[:, (i + l - 1) * d + 1], label="1-$i")
end
display(plot(p1, p2, p3, p4, p5, p6))
