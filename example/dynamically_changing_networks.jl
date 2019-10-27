# This file illustrates the simulation of a network consisting of dynamic systesm.

using Jusdl 
using Plots 

# Simulation settings 
t0 = 0
dt = 0.005
tf = 100.

# Define the network parameters 
numnodes = 5
dimnodes = 3
conmat = uniformconnectivity(:star_graph, numnodes, weight=10.)
cplmat = coupling(dimnodes, 1)
net = Network([LorenzSystem(Bus(dimnodes), Bus(dimnodes)) for i = 1 : numnodes],
    conmat, cplmat)
writer = Writer(Bus(length(net.output)))

# Connect the blocks
connect(net.output, writer.input)

# Construct the model 
model = Model(net, writer)

# Construct a callback for the model 
condition1(model) = model.clk.t >= 50.
action1(model, id=net.id) = changeweight(findin(model, id), 1, 3, 0.)
clb1 = Callback(condition1, action1)
addcallback(model, clb1)

# Simulate the model
sim = simulate(model, t0, dt, tf)

# Read and process the simulation data.
t, x = read(writer, flatten=true)
plots = [
    plot(t, x[:, 1]),
    plot(x[:, 1], x[:, 2]),
    plot(x[:, 4], x[:, 5]),
    [plot(t, abs.(x[:, 1] - x[:, 1 + i * dimnodes]), label=string(1) * "-" * string(i + 1))
        for i in 1 : numnodes - 1]...]
display(plot(plots...))
