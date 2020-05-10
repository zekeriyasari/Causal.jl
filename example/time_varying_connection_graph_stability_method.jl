# This file illustrates the simulation of connection graph stability method. 
# The network has time varying coupling.

using Jusdl 
using Plots

# Simulation settings 
t0, dt, tf = 0., 0.005, 200.

# Construct the components
numnodes = 6
dimnodes = 3
weight = 30.

# Adjust the coupling strenghs 
per = 100.
pulse(t, level1, level2) = mod(t, per) <= per / 4 ? level1 : level2
eps12(t) = pulse(t, weight, 0.)
eps21(t) = pulse(t, weight, 0.)
eps11(t) = pulse(t, -(numnodes - 1) * weight, -(numnodes - 2) * weight)
eps22(t) = pulse(t, -weight, 0.)

conmat = uniformconnectivity(:star_graph, numnodes, weight=weight, timevarying=true)
conmat[1, 1] = eps11
conmat[1, 2] = eps12
conmat[2, 1] = eps21
conmat[2, 2] = eps22
cplmat = coupling(dimnodes, 1)
net = Network([LorenzSystem(Bus(dimnodes), Bus(dimnodes)) for i = 1 : numnodes], conmat, cplmat)
writer = Writer(Bus(length(net.output)))

# Connect the components
connect!(net.output, writer.input)

# Construct the model
model = Model(net, writer)

# Simulate the model 
sim = simulate!(model, t0, dt, tf)

# Read the simulation data
t, x = read(writer, flatten=true)

# Plot the simulation data
plots = [
    plot(t, x[:, 1]),
    plot(x[:, 1], x[:, 2]),
    [   begin
        plot(t, abs.(x[:, 1] - x[:, 1 + i * dimnodes]), label=string(1) * "-" * string(i + 1))
        plot!(t, map(eps12, t), label="")
        end
        for i in 1 : numnodes - 1]...
    ]
# display(gplot(net))
display(plot(plots...))

# Plot constrol signals
t = collect(t0:dt:tf)
plots = [
    plot(t, map(eps12, t), label=:eps12),
    plot(t, map(eps21, t), label=:eps21),
    plot(t, map(eps11, t), label=:eps11),
    plot(t, map(eps22, t), label=:eps22)
    ]
display(plot(plots...))
