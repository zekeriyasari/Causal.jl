using LinearAlgebra 
using DifferentialEquations
using Plots 
using BlockArrays
using LightGraphs, GraphPlot

# Define node dynamics 
h(x, a=-1/7, b=2/7) = b * x + 1 / 2 * (a - b) * (abs(x + 1) - abs(x - 1))
function chua(dx, x, α=9, β=100/7, h=h)
    dx[1] = α * (x[2] - h(x[1]))
    dx[2] = x[1] - x[2] + x[3]
    dx[3] = -β * x[2]  
end
d = 3

# Define clusters
cls = [1:3, 4:6]
ks = length.(cls)
n = sum(ks)
l = length(ks)

# Define passivity index.
f = chua
Δ = diagm(ones(d)) * 10
P = diagm(ones(d))

# Define topology of the matrix 
μ(A) = 1 / 2 * maximum(size(A)) * maximum(abs.(A))
Φ = BlockArray([
    -1. 1 0 0 0 0;
    1 -2 1 0 -1 1;
    0 1 -1 0 1 -1;
    0 0 0 -1 1 0;
    0 -1 1 1 -2 1;
    0 1 -1 0 1 -1
    ], [3, 3], [3, 3])

μs = zeros(l * l - l)
k = 1 
for i = 1 : l, j = 1 : l
    global k
    if j != i 
        μs[k] = μ(getblock(Φ, i, j))
        k += 1
    end
end
μm = maximum(μs)
δm = maximum(diag(Δ))

# Define initial constants 
γs = [1, 1] * 200
Γiis = [diagm([zeros(k - 1); γ]) for (k, γ) in zip(ks, γs)]
Φiis = [getblock(Φ, i, i) for i = 1 : l]
λs = [-maximum(eigvals(Φii - Γii)) for (Φii, Γii) in zip(Φiis, Γiis)]
βis = (δm + 2 * (l - 1) * μm) ./ λs
β = maximum(βis) * 0.02  # The condition is not statisfied.

αs = β * γs
# αs = [5., 5.]
E = copy(Φ)
for i = 1 : l 
    setblock!(E, getblock(E, i, i)*β, i, i)
end
E = [zeros(l, l) zeros(l, n); zeros(n, l) E]
H1 = zeros(n, l)
for (k, (j, α)) in zip(cumsum(ks), enumerate(αs))
    H1[k, j] = -α
end
H2 = zeros(n, n)
for (k, α) in zip(cumsum(ks), αs)
    H2[k, k] = α
end
H = [zeros(l, l + n); [H1 H2]]

# Define coupled network dynamics
function statefunc(dx, x, u, t, f=f, E=E, H=H, P=P)
    n = size(E, 1)
    d = size(P, 1)
    # Individual evolution
    for i = 1 : n
        f(view(dx, (i - 1) * d + 1 : i * d), view(x, (i - 1) * d + 1 : i * d)) 
    end
    # Add coupling and control inputs
    dx .+= kron(E - H, P) * x
end

# Simulation network
tspan = (0., 100.)
x0 = rand((n + l) * d) * 1e-3
@info "Solving network..."
sol = solve(ODEProblem(statefunc, x0, tspan))
@info "Done..."
states = collect(hcat(sol.u...)')
t = collect(vcat(sol.t...))

# Plot the results
graph = SimpleDiGraph(E - H)
display(gplot(graph, nodelabel=1 : (n + l)))
p1 = plot(t, states[:, 1])
p2 = plot(states[:, 1], states[:, 2])
p3 = plot(states[:, 1] - states[:, 7])
    plot!(states[:, 1] - states[:, 10])
    plot!(states[:, 1] - states[:, 13])
p4 = plot(states[:, 4] - states[:, 16])
    plot!(states[:, 4] - states[:, 19])
    plot!(states[:, 4] - states[:, 22])
p5 = plot(states[:, 1] - states[:, 4])
p6 = plot(states[:, 7] - states[:, 16])
display(plot(p1, p2, p3, p4, p5, p6))
