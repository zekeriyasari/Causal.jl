# This file includes the simulation of LorenzSystem System in a unity-feedback system.

using Jusdl 
using Plots; pyplot()
using LinearAlgebra

# Construct the model 
α = 0.001
model = Model(clock=Clock(0., 0.01, 100)) 
model[:gen] = FunctionGenerator(t -> zeros(3))
model[:adder] = Gain(Inport(6), gain=α*[diagm(ones(3)) -diagm(ones(3))])
model[:ds] = LorenzSystem(Inport(3), Outport(3))
model[:writer] = Writer(Inport(3))
model[:gen => :adder] = Indices(1:3 => 1:3)
model[:adder => :ds] = Indices(1:3 => 1:3)
model[:ds => :adder] = Indices(1:3 => 4:6)
model[:ds => :writer] = Indices(1:3 => 1:3)

# Display model signal flow before breaking algebraic loop
display(signalflow(model))

# Simulate the model 
simulate!(model)

# Display model signal flow before breaking algebraic loop
display(signalflow(model))

# Read the simulation. 
t, x = read(model[:writer].component)
p1 = plot(t, x[:, 1], label=:x1)
p2 = plot(x[:, 1], x[:, 2], label=:x1_x2)
display(plot(p1, p2))
