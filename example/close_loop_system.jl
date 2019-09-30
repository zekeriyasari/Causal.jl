# This file includes a simple closed-loop system simulation.

using Jusdl 
using Plots 

# Define the components
f(dx, x, u, t) = (dx[1] = -x[1] + u[1])
g(x, u, t) = x
ds = ODESystem(f, g, [1.], 0., Bus(1), Bus(1))
gen = SinewaveGenerator(1, 1/100)
mem = Memory(Bus(1), 1, [0.])
adder = Adder(Bus(2), (+,-))
writer1 = Writer(Bus(1))
writer2 = Writer(Bus(1))

# Connect the components
connect(gen.output, adder.input[1])
connect(adder.output, ds.input)
connect(ds.output, mem.input)
connect(mem.output, adder.input[2])
connect(gen.output, writer2.input)
connect(ds.output, writer1.input)
model = Model(gen, adder, ds, mem, writer1, writer2)

# Simulate the model 
sim = simulate(model, 0., 0.01, 100.)

# Process the simulation data.
content1 = read(writer1)
vals1 = collect(hcat(vcat(collect(values(content1))...)...)')
content2 = read(writer2)
vals2 = collect(hcat(vcat(collect(values(content2))...)...)')
t = vcat(collect(keys(content1))...)
plot(t, vals1)
plot(t, vals2)
