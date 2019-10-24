using Jusdl 
using Plots
using LinearAlgebra

# Simulationk settings 
t0, dt, tf = 0., 0.01, 50.

# Construct model components
numnodes = 2
dimnodes = 3
net = Network([LorenzSystem(Bus(dimnodes), Bus(dimnodes)) for i = 1 : numnodes], 
    getconmat(:path_graph, numnodes, weight=5.), getcplmat(dimnodes, 1))
writer = Writer(Bus(length(net.output)))

# Connect model components
connect(net.output, writer.input)

# Construct the model 
model = Model(net, writer)

# Simuate the model
sim = simulate(model, t0, dt, tf)

# Check termination of the tasks 
foreach(comp -> display(model.taskmanager.pairs[comp]), model.blocks)

# Read simulation data 
t, x = read(writer, flatten=true)

# Plot the results 
# p1 = gplot(net)
p2 = plot(t, x[:, 1])
p3 = plot(x[:, 1], x[:, 2])
p4 = plot(t, x[:, 1] - x[:, 4])
display(p1)
display(plot(p2, p3, p4, layout=(3, 1)))
