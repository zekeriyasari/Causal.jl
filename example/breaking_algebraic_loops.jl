# This file illustrates the use of memory blocks to break algebraic loops

using Jusdl 
using Plots 

# Simualation settings 
t0, dt, tf = 0, 1 / 64, 1.

# Construct model blocks 
gen = FunctionGenerator(identity)
adder = Adder(Bus(2), (+, -))
mem = Memory(Bus(1), 1, initial=0)    # Initial condition is very important for accurate solutions. 
writerout = Writer(Bus(length(adder.output)))
writerin = Writer(Bus(length(gen.output)))

# Connect model blocks 
connect!(gen.output, adder.input[1])
connect!(mem.output, adder.input[2])
connect!(adder.output, mem.input)
connect!(mem.output, writerout.input)
connect!(gen.output, writerin.input)

# Construct the model 
model = Model(gen, adder, mem, writerout, writerin)

# Simulate the model 
sim = simulate!(model, t0, dt, tf)

# Diplay model taskmanager
display(model.taskmanager.pairs)

# Read the simulation data 
t, y = read(writerout, flatten=true)
t, u = read(writerin, flatten=true)

# Plot the results
p1 = plot(t, u, label=:u, marker=(:circle, 1)) 
    plot!(t, y, label=:y, marker=(:circle, 1)) 
display(p1)
