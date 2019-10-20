# This file illustrates the simulation of cluster synchronization in a network consisting of a large number of 
# oscillators.

using Jusdl 
using Plots 

# Simulation settings 
t0, dt, tf = 0., 0.001, 50.

# Construct the model blocks
clusters = (1:3, 4:10, 11:20)
numnodes = clusters[end][end]
dimnodes = 3
conmat = getconmat(clusters..., weight=5.)
cplmat = getcplmat(dimnodes, 1)
net = Network([LorenzSystem(Bus(dimnodes), Bus(dimnodes)) for i = 1 : numnodes], conmat, cplmat)
writer = Writer(Bus(length(net.output)))

# Connect the model blocks 
connect(net.output, writer.input)

# Construct the model 
model = Model(net, writer)

# Simulate the model 
sim = simulate(model, t0, dt, tf)

# Read simulation data
t, x = read(writer, flatten=true)

# Plot the results
p1 = plot(t, x[:, 1], label=:(1))
p2 = plot(x[:, 1], x[:, 2], label=:(traj_1))
p3 = plot()
for cluster in clusters
    for node in cluster[1] : cluster[end - 1]
        plot!(t, abs.(x[:, (node - 1) * dimnodes + 1] - x[:, node * dimnodes + 1]), label=:($node - $(node + 1)))
    end
end
p4 = plot()
for n = 1 : length(clusters) - 1
    node1 = clusters[n][1]
    node2 = clusters[n + 1][1]
    plot!(t, abs.(x[:, (node1 - 1) * dimnodes + 1] - x[:, (node2 - 1) * dimnodes + 1]), label=:($node1 - $node2))
end
display(gplot(net))
display(plot(p1, p2, p3, p4, layout=(2,2)))
