# This file includes am example illustrating the connection of writers to input busses.

using Jusdl
using Plots 

# Construct the components
gen = SinewaveGenerator()
gain = Gain(Bus(), gain=-2.)
writerin = Writer(Bus(length(gain.input)))
writerout = Writer(Bus(length(gain.output)))

# Connect the components
connect(gen.output, gain.input)
connect(gain.input, writerin.input)
connect(gain.output, writerout.input)

# Construct the model
model = Model(gen, gain, writerin, writerout)

# Simulate the model 
sim = simulate(model, 0., 0.01, 10.)

# Check the task termination 
display(model.taskmanager.pairs)

# Plot the simulation data.
t, uin = read(writerin, flatten=true)
t, uout = read(writerout, flatten=true)
p1 = plot(t, uin, label=:uin)
    plot!(t, uout, label=:uuut)
display(p1)
