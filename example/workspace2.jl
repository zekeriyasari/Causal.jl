# Simulation of coupled chaotic dynamic systems under excess coupling strength  

using Jusdl 
using Plots; pyplot()

# Simulation settings 
t0, dt, tf = 0., 0.01, 100.

# Construct model components 
ds1 = LorenzSystem(Bus(3), Bus(3), state=ones(3))
ds2 = LorenzSystem(Bus(3), Bus(3), state=ones(3) + 0.01)
mem1 = Memory(Bus(3), 500, initial=ones(3))
mem2 = Memory(Bus(3), 500, initial=ones(3))
coupler = Coupler([-1 1; 1 -1] * 500, [1 0 0; 0 0 0; 0 0 0])
writer1 = Writer(Bus(length(ds1.output)))
writer2 = Writer(Bus(length(ds2.output)))
writer3 = Writer(Bus(length(mem1.output)))
writer4 = Writer(Bus(length(mem2.output)))

# Connect the component 
connect(ds1.output, coupler.input[1:3])
connect(coupler.output[1:3], mem1.input)
connect(mem1.output, ds1.input)
connect(ds2.output, coupler.input[4:6])
connect(coupler.output[4:6], mem2.input)
connect(mem2.output, ds2.input)
connect(ds1.output, writer1.input)
connect(ds2.output, writer2.input)
connect(mem1.output, writer3.input)
connect(mem2.output, writer4.input)

# Construct the model 
model = Model(ds1, ds2, mem1, mem2, coupler, writer1, writer2, writer3, writer4)

# Simulate the model 
sim = simulate(model, t0, dt, tf)

# Read the simulation data 
t, x1 = read(writer1, flatten=true)
t, x2 = read(writer2, flatten=true)
t, x3 = read(writer3, flatten=true)
t, x4 = read(writer4, flatten=true)

# Plot the simulation data 
p1 = plot(t, x1[:, 1])
    plot!(t, x2[:, 1])
    plot!(t, x3[:, 1])
p2 = plot(x1[:, 1], x1[:, 2])
p3 = plot(x2[:, 1], x2[:, 2])
p4 = plot(abs.(x1[:, 1] - x2[:, 1]))
display(plot(p1, p2, p3, p4, layout=(2,2)))

