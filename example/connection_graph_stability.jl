# This file illustrates the simulation of connection graph stability method.

using Jusdl 
using Plots 

# Simulation parameters
t0 = 0
dt = 0.01
tf = 50

# Define the network parameters 
numnodes = 6
dimnodes = 3
weight = 10.
# conmat = [
#     -8. 5. 3. 0. 0. 0.;
#     5. -38. 13. 0 10. 10.;
#     3. 13. -27. 11. 0. 0.;
#     0. 0. 11. -11. 0. 0.;
#     0. 10. 0. 0. -10. 0.;
#     0. 10. 0. 0. 0. -10. 
#     ] * weight / numnodes
conmat = [
    -11. 0. 11. 0. 0. 0.;  # When the link between node 1 and 2 is removed.
    0. -39. 21. 0. 9. 9.;
    11. 21. -43. 11. 0. 0.;
    0. 0. 11. -11. 0. 0.;
    0. 9. 0. 0. -9. 0.;
    0. 9. 0. 0. 0. -9. 
    ] * weight / numnodes
cplmat = [
    1. 0. 0.;
    0. 0. 0.; 
    0. 0. 0.;
    ]
net = Network([LorenzSystem(Bus(dimnodes), Bus(dimnodes)) for i = 1 : numnodes], conmat, cplmat)
writer = Writer(Bus(length(net.output)))

# Connect the blocks
connect(net.output, writer.input)

# Construct the model 
model = Model(net, writer)

# Simulate the moadel 
sim = simulate(model, t0, dt, tf)

# Read and process the simulation data.
t, x = read(writer, flatten=true)
p1 = plot(t, x[:, 1], linewidth=2)
p2 = plot(x[:, 1], x[:, 2])
p3 = plot()
for n in 1 : numnodes - 1
    plot!(t, abs.(x[:, (n - 1) * dimnodes + 1] - x[:, n * dimnodes + 1]))
end
display(gplot(net))
display(plot(p1, p2, p3, layout=(3,1)))
