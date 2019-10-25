
using Jusdl 
using Plots 
using LinearAlgebra

# Construct model blocks.
ds = LinearSystem(nothing, Bus())
writerout = Writer(Bus(length(ds.output)))

# Connect model blocks.
connect(ds.output, writerout.input)

# Construct model 
model = Model(ds, writerout)

initialize(model)
set!(model.clk, 0., 0.01, 10.)
# run(model)

# # Simulate the model
# sim = simulate(model, 0., 0.01, 20.)

# # Plot simulation plots
# t, y = read(writerout, flatten=true)
# p1 = plot(t, y)
# display(p1)
