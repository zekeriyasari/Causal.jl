# This file illustrates the simulation of connection graph stability method. 
# Connectivity matrix is constructed using adjacency matrix.

using Jusdl 
using Plots

# Simulation settings 
t0, dt, tf = 0., 0.001, 50.

# Construct the components
numnodes = 6
dimnodes = 3
weight = 50.
adjmat = [
    0 1 1 0 0 0;
    1 0 1 0 1 1;
    1 1 0 1 0 0;
    0 0 1 0 0 0;
    0 1 0 0 0 0;
    0 1 0 0 0 0
    ]
conmat = cgsconnectivity(adjmat, weight=weight)
cplmat = coupling(dimnodes, 1)
net = Network([LorenzSystem(Bus(dimnodes), Bus(dimnodes)) for i = 1 : numnodes], conmat, cplmat)
writer = Writer(Bus(length(net.output)))

# Connect the components
connect(net.output, writer.input)

# Construct the model
model = Model(net, writer)

# # Add callback to the model 
# condition(model) = model.clk.t >= tf / 2
# action(model, id=net.id) = deletelink(findin(model, id), 1, 2)
# addcallback(model, Callback(condition, action))

# Simulate the model 
sim = simulate(model, t0, dt, tf)

# Read the simulation data
t, x = read(writer, flatten=true)

# Plot the simulation data
plots = [
    plot(t, x[:, 1]),
    plot(x[:, 1], x[:, 2]),
    [plot(t, abs.(x[:, 1] - x[:, 1 + i * dimnodes]), label=string(1) * "-" * string(i + 1))
        for i in 1 : numnodes - 1]...]
display(plot(plots...))
