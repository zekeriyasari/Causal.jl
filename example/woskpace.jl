# A simple example file 

using Jusdl 
using Plots

t0, dt, tf = 0, 0.001, 10

gen = SinewaveGenerator()
writer = Writer(Bus(length(gen.output)))

connect(gen.output, writer.input)

model = Model(gen, writer)

sim = simulate(model, t0, dt, tf)

t, x = read(writer, flatten=true)

p1 = plot(t, x[:, 1])
display(p1)
