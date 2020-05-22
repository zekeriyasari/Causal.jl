using Jusdl 
using Plots 
using LightGraphs

# Extract network dimension 
n = 100
d = 3
ε = 1.
E = collect(-laplacian_matrix(erdos_renyi(n, 0.2)))
P = [1 0 0; 0 0 0; 0 0 0]

# Construct the model 
model = Model(clock=Clock(0, 0.01, 100))

# Add nodes to the model
foreach(i -> addnode!(model, LorenzSystem(Inport(d), Outport(d)), label=Symbol("node", i)), 1 : n)
addnode!(model, Coupler(ε * E, P), label=:coupler)
addnode!(model, Writer(Inport(n * d)), label=:writer)

# Add branches to the model 
cidx, widx = n + 1, n + 2
for (j, k) in zip(1 : n, map(i -> i : i + d - 1, 1 : d : n * d))
    addbranch!(model, j => cidx, 1 : d => k)
    addbranch!(model, cidx => j, k => 1 : d)
    addbranch!(model, j => widx, 1 : d => k)
end

# Simulate the model
@time simulate!(model)

# Plot simulation data 
t, x = read(getnode(model, n + 2).component)
plt = plot(layout=(2, 1))
plot!(t, x[:, 1], label="node1", subplot=1)
plot!(t, abs.(x[:, 1] - x[:, 10]), label="error12", subplot=2)
display(plt)
