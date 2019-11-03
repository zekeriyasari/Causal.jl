using Jusdl
using Plots 

# Simulation settings 
t0, dt, tf = 0., 0.001, 100.

# Construct model blocks 
ds = ChenSystem(nothing, Bus(3))
writer = Writer(Bus(length(ds.output)))

# Connect model blocks 
connect(ds.output, writer.input)

# Construct model 
model = Model(ds, writer)

# Simulate model 
sim = simulate(model, t0, dt, tf)

# Plot results 
t, x = read(writer, flatten=true)
plots = [
    plot(t, x[:, 1], label=:x1),
    plot(t, x[:, 2], label=:x1),
    plot(t, x[:, 3], label=:x1),
    plot(x[:, 1], x[:, 2], label=:x1x2),
    plot(x[:, 1], x[:, 3], label=:x1x3),
    plot(x[:, 2], x[:, 3], label=:x2x3)
    ]
display(plot(plots...))