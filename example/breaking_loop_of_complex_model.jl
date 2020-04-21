# This file includes the simulation of a model consisting an algrebraic loop with multiple inneighbor branches joinin an algrebraic loop.

using Jusdl 
using Plots; pyplot() 

model = Model() 
model[:gen] = SinewaveGenerator(frequency=2)
model[:gen2] = SinewaveGenerator(frequency=3)
model[:adder2] = Adder((+, +))
model[:gain1] = Gain(gain=1)
model[:adder] = Adder((+,-, +))
model[:gain2] = Gain(gain=1) 
model[:gain3] = Gain(gain=1) 

model[:writer] = Writer(Inport(2))

model[:gen => :gain1] = Indices(1 => 1)
model[:gain1 => :adder] = Indices(1 => 1)
model[:gen2 => :adder2] = Indices(1 => 1)
model[:gen => :adder2] = Indices(1 => 2)

model[:adder => :gain2] = Indices(1 => 1)
model[:gain2 => :gain3] = Indices(1 => 1)
model[:gain3 => :adder] = Indices(1 => 2)
model[:adder2 => :adder] = Indices(1 => 3)

model[:gen => :writer] = Indices(1 => 1)
model[:gain2 => :writer] = Indices(1 => 2)

display(gplot(model, linetype="curve"))
simulate(model)
t, x = read(model[:writer].component)
plot(t, x[:, 1], label=:gen)
plot!(t, x[:, 2], label=:gain)