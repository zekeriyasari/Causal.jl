using Jusdl 
using Plots 

# Define the network parameters 
numnodes = 2
nodes = [LorenzSystem(Bus(3), Bus(3)) for i = 1 : numnodes]
conmat = [-10 10; 10 -10]
cplmat = [1 0 0; 0 0 0; 0 0 0]
net = Network(nodes, conmat, cplmat)
writer = Writer(Bus(length(net.output)))

# Connect the blocks
connect(net.output, writer.input)

# Construct the model 
model = Model(net, writer)

# Simulate the model 
sim = simulate(model, 0, 0.01, 10)

# Read and process the simulation data.
content = read(writer)
t = vcat(collect(keys(content))...)
x = collect(hcat(vcat(collect(values(content))...)...)')
plot(t, x[:, 1])
plot!(t, x[:, 4])
plot(t, abs.(x[:, 1] - x[:, 4]))
