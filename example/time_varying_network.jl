using Jusdl 
using Plots 

# Simulation settings 
t0 = 0
dt = 0.001
tf = 500.

# Define the network parameters 
numnodes = 2
dimnodes = 3
weightpos(t, high=5., low=0., per=100.) = (0 <= mod(t, per) <= per / 2) ? high : low
weightneg(t, high=-5., low=0., per=100.) = (0 <= mod(t, per) <= per / 2) ? high : low
net = Network([LorenzSystem(Bus(dimnodes), Bus(dimnodes)) for i = 1 : numnodes], 
    [weightneg weightpos; weightpos weightneg],
    getcplmat(dimnodes, 1))
writer = Writer(Bus(length(net.output)))

# Connect the blocks
connect(net.output, writer.input)

# Construct the model 
model = Model(net, writer)

# Simulate the model 
sim = simulate(model, 0, 0.01, 500)

# Read and process the simulation data.
t, x = read(writer, flatten=true)
p1 = plot(t, x[:, 1], label=:x1)
    plot!(t, x[:, 4], label=:x2)
p2 = plot(t, abs.(x[:, 1] - x[:, 4]), label=:err)
    plot!(t, map(weightpos, t), label=:coupling)
display(plot(p1, p2, layout=(2,1)))
