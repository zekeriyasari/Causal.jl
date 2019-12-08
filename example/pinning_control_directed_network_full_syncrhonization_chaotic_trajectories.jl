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

a = -1.27
b = -0.68
α = 10
β = 14.87
h(x, a=-1.27, b=-0.68) = b * x + 1 / 2 * (a - b) * (abs(x + 1) - abs(x - 1))
function chua(dx, x, α=10, β=14.87, h=h)
    dx[1] = α * (x[2] - x[1] - h(x[1]))
    dx[2] = x[1] - x[2] + x[3]
    dx[3] = -β * x[2]  
end
A = [-α α 0; 1 -1 1; 0 -β 0]
Atilde = A + diagm([abs(a * α), 0 , 0])

# Define passivity index.
θ = 1 / 2 * maximum(eigvals(Atilde + Atilde'))

# Determine a network topology
n = 10
d = 3
f = chua
Ξ = [
    -1 0 0 0 0 0 0 0 1 0;
    0 -1 0 0 0 0 1 0 0 0;
    1 0 -2 0 1 0 0 0 0 0;
    0 0 1 -1 0 0 0 0 0 0;
    0 0 0 1 -1 0 0 0 0 0;
    0 0 1 0 0 -1 0 0 0 0;
    0 0 0 0 0 0 -1 1 0 0;
    1 1 0 0 0 0 0 -3 0 1;
    0 1 0 0 0 0 0 1 -2 0;
    1 0 0 0 0 1 0 0 0 -2;
]

# Ξ = [
#     -1 0 0 0 0 0 0 0 0 1;
#     1 -2 0 0 0 0 0 0 1 0;
#     0 1 -1 0 0 0 0 0 0 0;
#     0 0 1 -2 0 1 0 0 0 0;
#     0 0 0 1 -1 0 0 0 0 0;
#     0 0 0 0 1 -1 0 0 0 0;
#     0 0 0 1 0 0 -1 0 0 0;
#     0 0 1 0 0 0 1 -2 0 0;
#     1 0 1 0 0 0 0 1 -3 0;
#     0 0 0 0 0 1 0 0 1 -1;
# ]
# # Investigate the eigenvalues 
# δrange = 0.1:0.1:0.9
# λs = zeros(length(δrange))
# for k = 1 : length(δrange)
#     l = floor(Int, δrange[k]*n)
#     mat = Ξ[1:l, 1:l]
#     λs[k] = maximum(eigvals((mat + mat') ./ 2))
# end
# plot(δrange, λs, marker=(:circle))

P = diagm([1, 1, 1])
ϵ = 60

# Determine pinned nodes 
l = 1
Ω = BlockArray(θ * diagm(ones(n)) + ϵ / 2 * (Ξ + Ξ'), [l, n - l], [l, n - l])
Ω11 = getblock(Ω, 1, 1)
Ω12 = getblock(Ω, 1, 2)
Ω22 = getblock(Ω, 2, 2)
α = maximum(eigvals(Ω11 - Ω12 * inv(Ω22) * Ω12')) * 0.0001  # Condition is not satisfied.

# Compute coupling strength threshold
A = diagm(vcat([α for i = 1 : l], zeros(n - l)))

G = ϵ * kron([zeros(n + 1) vcat(zeros(1, n), Ξ)], P)
H = kron([zeros(1, n + 1); diagm(diag(A))' * [-ones(n) diagm(ones(n))]], P)
# Define coupled network dynamics
function statefunc(dx, x, u, t, f=f, G=G, H=H)
    n = size(Ξ, 1)
    d = size(P, 1)
    # Individual evolution
    for i = 1 : n + 1
        f(view(dx, (i - 1) * d + 1 : i * d), view(x, (i - 1) * d + 1 : i * d)) 
    end
    dx .+= (G - H) * x
end

# Simulation network
tspan = (0., 100.)
x0 = rand((n + 1) * d) * 1e-3
@info "Solving network..."
sol = solve(ODEProblem(statefunc, x0, tspan))
@info "Done..."
states = collect(hcat(sol.u...)')
t = collect(vcat(sol.t...))

# Plot the results
p1 = plot(t, states[:,1], label="")
p2 = plot(states[:,1], states[:,2], label="")
p3 = plot()
foreach(i -> plot!(t, states[:, 1] - states[:, (i - 1) * d + 1], label=""), 2:n)
p4 = plot()
foreach(i -> plot!(t, states[:, 2] - states[:, (i - 1) * d + 2], label=""), 2:n)
p5 = plot()
foreach(i -> plot!(t, states[:, 3] - states[:, (i - 1) * d + 3], label=""), 2:n)
display(gplot(graph, nodelabel=1:nv(graph)))
display(plot(p1, p2, p3, p4, p5))
