# This file illustrates the simulation of a subsystem.

using Jusdl 
using Plots; pyplot()

# Construct a subsystem
gain1 = Gain(Inport(), gain=2.)
gain2 = Gain(Inport(), gain=4)
mem = Memory(Inport(), 50, initial=rand(1))
connect(gain1.output, mem.input)
connect(mem.output, gain2.input)

sub = SubSystem([gain1, gain2, mem], gain1.input, gain2.output, name=:sub)

# Construct a source and a sink.
gen = FunctionGenerator(sin, name=:gen)
writer = Writer(Inport(), name=:writer)

model = Model([gen, sub, writer], clock=Clock(0, 0.01, 10))
addconnection(model, :gen, :sub)
addconnection(model, :sub, :writer)

# Simulate the model 
sim = simulate(model)

# Read and plot simulation data 
t, x = read(writer, flatten=true)
display(plot(t, x))

# Display the task status
display(model.taskmanager.pairs[sub])
