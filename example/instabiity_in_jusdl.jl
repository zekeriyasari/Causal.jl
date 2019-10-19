using Jusdl 
using Plots 

# Simualation settings 
t0, dt, tf = 0, 0.01, 10

# Construct the components 
gen = FunctionGenerator(t -> exp(t))
ds = LorenzSystem(Bus(1), Bus(3), cplmat = reshape([1, 0, 0], 3, 1))
writerin = Writer(Bus(length(ds.input)))
writerout = Writer(Bus(length(ds.output)))

# Connect the components
connect(gen.output, ds.input)
connect(ds.input, writerin.input)
connect(ds.output, writerout.input)

# Construct the model 
model = Model(gen, ds, writerin, writerout)

# Simulate the model
sim = simulate(model, t0, dt, tf)

# Read simulation data 
t, u = read(writerin, flatten=true)
t, x = read(writerout, flatten=true)

# Plot the simulation data 
plot(t, x[:, 1], label=:x1)
plot!(t, u, label=:u)

