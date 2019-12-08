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
n = 6
δ = 0.5
d = 3
l = floor(Int, δ * n)
r = n - l
f = chua
Ξ = [
    -1  1   0   0   0   0; 
    1  -3   1   1   0   0; 
    0  1   -1   0   0   0; 
    0  1   0   -3   1   1; 
    0  0   0   1   -1   0; 
    0  0   0   1   0   -1
]
graph = SimpleGraph(Ξ)
# graph = star_graph(n)
# graph = static_scale_free(n, 100, 5)
P = diagm([1, 1, 1])
Ξ11, Ξ12, Ξ21, Ξ22 = Ξ[1 : l, 1 : l], Ξ[1 : l, l + 1 : n], Ξ[l + 1 : n, 1 : l], Ξ[l + 1 : n, l + 1 : n] 

# Compute coupling strength threshold
ϵ = θ / abs(maximum(eigvals(Ξ22))) * 2

# Compute control gain threshold
Γ = θ * diagm(ones(n)) + ϵ * Ξ
Γ11, Γ12, Γ21, Γ22 = Γ[1 : l, 1 : l], Γ[1 : l, l + 1 : n], Γ[l + 1 : n, 1 : l], Γ[l + 1 : n, l + 1 : n] 
α = 1 / ϵ * maximum(eigvals(Γ11 - Γ12 * inv(Γ22) * Γ12')) * 2
A = diagm(vcat([α for i = 1 : l], zeros(r)))

G = ϵ * kron([zeros(n + 1) vcat(zeros(1, n), Ξ)], P)
H = ϵ * kron([zeros(1, n + 1); diagm(diag(A))' * [-ones(n) diagm(ones(n))]], P)
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
