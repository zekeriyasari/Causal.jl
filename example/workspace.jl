# This file illustrates the simulation of a network consisting of dynamic systesm.

using Jusdl 
using Plots 

# Simulation settings 
t0 = 0
dt = 0.01
tf = 100.

# Define the network parameters 
numnodes = 2
ds1 = LorenzSystem(Bus(3), Bus(3)) 
ds2 = LorenzSystem(Bus(3), Bus(3)) 
mem1 = Memory(Bus(3), 1)
mem2 = Memory(Bus(3), 1)
conmat = [-1. 1.; 1. -1.] * 110.
cplmat = [1 0 0; 0 0 0; 0 0 0]
coupler = Coupler(conmat, cplmat)
writer1 = Writer(Bus(length(ds1.input)))
writer2 = Writer(Bus(length(ds1.output)))
writer3 = Writer(Bus(length(ds2.input)))
writer4 = Writer(Bus(length(ds2.output)))

# Connect the blocks
connect(ds1.output, coupler.input[1:3])
connect(ds2.output, coupler.input[4:6])
connect(coupler.output[1:3], mem1.input)
connect(coupler.output[4:6], mem2.input)
connect(mem1.output, ds1.input)
connect(mem2.output, ds2.input)
connect(ds1.output, writer1.input)
connect(ds1.output, writer2.input)
connect(ds2.output, writer3.input)
connect(ds2.output, writer4.input)

# Construct the model 
model = Model(ds1, ds2, coupler, mem1, mem2, writer1, writer2, writer3, writer4)

sim = simulate(model, t0, dt, tf)


# Read and process the simulation data.
t, u1 = read(writer1, flatten=true)
t, x1 = read(writer2, flatten=true)
t, u2 = read(writer3, flatten=true)
t, x2 = read(writer4, flatten=true)
p1 = plot(t, u1[:, 1], label=:u1)
    plot!(t, x1[:, 1], label=:x1)
p2 = plot(t, u2[:, 1], label=:u2)
    plot!(t, x2[:, 1], label=:u2)
p3 = plot(t, abs.(x1[:, 1] - x2[:, 1]), label=:error)
display(plot(p1, p2, p3, layout=(3,1)))
