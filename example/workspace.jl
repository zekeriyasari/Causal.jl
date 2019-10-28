
using Jusdl 
using Plots

# Simulation settings 
t0, dt, tf = 0., 0.01, 100.

ds = VanderpolSystem(nothing, Bus(2))
writer = Writer(Bus(length(ds.output)))

# connect(gen.output, ds.input)
connect(ds.output, writer.input)

# model = Model(gen, ds, writer)
model = Model(ds, writer)

sim = simulate(model, t0,dt, tf)

t, x = read(writer, flatten=true)

display(plot(t, x))