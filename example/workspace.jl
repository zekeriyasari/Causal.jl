using Jusdl 
using Plots 

# Define the network parameters 
numnodes = 2
dimnodes = 3
weight = 50.
net = Network([LorenzSystem(Bus(dimnodes), Bus(dimnodes)) for i = 1 : numnodes], 
    getconmat(:cycle_graph, numnodes, weight=weight), getcplmat(dimnodes, 1))
writer = Writer(Bus(length(net.output)))

# Connect the blocks
connect(net.output, writer.input)

# Construct the model 
model = Model(net, writer)

# Simulate the model 
sim = simulate(model, 0, 0.01, 100)

# Read and process the simulation data.
gplot(net)
t, x = read(writer, flatten=true)
plot(t, x[:, 1])
plot(x[:, 1], x[:, 2])
plot(t, abs.(x[:, 1] - x[:, 4]))