using Jusdl 
using Plots 

# Simulation parameters
t0 = 0
dt = 0.01
tf = 50

# Define the network parameters 
numnodes = 10
dimnodes = 3
weight = 1.
net = Network([LorenzSystem(Bus(dimnodes), Bus(dimnodes)) for i = 1 : numnodes], 
    getconmat(:erdos_renyi, numnodes, 0.7, weight=weight), getcplmat(dimnodes, 1))
writer = Writer(Bus(length(net.output)))

# Connect the blocks
connect(net.output, writer.input)

# Construct the model 
model = Model(net, writer)

# Simulate the moadel 
sim = simulate(model, t0, dt, tf)

# Read and process the simulation data.
gplot(net)
t, x = read(writer, flatten=true)
p1 = plot(t, x[:, 1])
p2 = plot(x[:, 1], x[:, 2])
p3 = plot()
for n in 1 : numnodes - 1
    plot!(t, abs.(x[:, (n - 1) * dimnodes + 1] - x[:, n * dimnodes + 1]), label="")
end
display(gplot(net))
display(plot(p1, p2, p3, layout=(3,1)))
