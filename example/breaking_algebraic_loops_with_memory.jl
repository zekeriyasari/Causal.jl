# This file illustrates the use of memory blocks to break algebraic loops

using Causal 
using Plots 

# Simualation settings 
t0, dt, tf = 0, 1 / 64, 1.

# Construct the model
@defmodel model begin 
    @nodes begin 
        gen = FunctionGenerator(readout=identity)
        adder = Adder(signs = (+, -))
        mem = Memory(delay = dt)
        writer = Writer(input=Inport(2))
    end 
    @branches begin 
        gen[1]      =>      adder[1]
        adder[1]    =>      mem[1]
        mem[1]      =>      adder[2]
        gen[1]      =>      writer[1]
        adder[1]    =>      writer[2]
    end
end

# Simulate the model 
sim = simulate!(model, t0, dt, tf)

# Diplay model taskmanager
display(model.taskmanager.pairs)

# Read the simulation data 
t, x = read(getnode(model, :writer).component)

# Plot the results
p1 = plot(t, x[:, 1], label=:u, marker=(:circle, 1)) 
    plot!(t, x[:, 2], label=:y, marker=(:circle, 1)) 
display(p1)
