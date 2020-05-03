# This file includes the simulation of a model consisting an algrebraic loop with multiple inneighbor branches joinin an algrebraic loop.

using Jusdl 
using Plots; pyplot() 

model = Model() 
addnode(model, SinewaveGenerator(frequency=2), label=:gen1)
addnode(model, Gain(gain=1), label=:gain1)
addnode(model, Adder((+,+)), label=:adder1)
addnode(model, SinewaveGenerator(frequency=3), label=:gen2)
addnode(model, Adder((+, +, -)), label=:adder2)
addnode(model, Gain(gain=1), label=:gain2)
addnode(model, Writer(), label=:writer)
addnode(model, Gain(gain=1), label=:gain3)
addbranch(model, :gen1 => :gain1, 1 => 1)
addbranch(model, :gain1 => :adder1, 1 => 1)
addbranch(model, :adder1 => :adder2, 1 => 1)
addbranch(model, :gen2 => :adder1, 1 => 2)
addbranch(model, :gen2 => :adder2, 1 => 2)
addbranch(model, :adder2 => :gain2, 1 => 1)
addbranch(model, :gain2 => :writer, 1 => 1)
addbranch(model, :gain2 => :gain3, 1 => 1)
addbranch(model, :gain3 => :adder2, 1 => 3)

simulate(model)
t, x = read(getnode(model, :writer).component)
plot(t, x)
