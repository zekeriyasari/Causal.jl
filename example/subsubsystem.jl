# This file illustrates the simulation of a subsystem including another subsystem.

using Jusdl 
using Plots 

# Time settings 
t0, dt, tf = 0., 0.001, 10.

# Construct the blocks 
dc = ConstantGenerator()
adder = Adder(Bus(2))
connect(dc.output, adder.input[1])
sub1 = SubSystem([dc, adder], adder.input[[2]], adder.output)

gain = Gain(Bus(1), gain=2)
connect(sub1.output, gain.input)
sub2 = SubSystem([sub1, gain], sub1.input, gain.output)

sine = SinewaveGenerator()
writer = Writer(Bus(length(sub2.output)))

# Connect components 
connect(sine.output, sub2.input)
connect(sub2.output, writer.input)

# Construct model 
model = Model(sine, sub2, writer)

# Simulate model 
sim = simulate(model, t0, dt, tf)

# Read simulation data 
t, x = read(writer, flatten=true)

# Plot results 
p1 = plot(t, x[:, 1])
display(p1)
