using Jusdl 
using Plots

gen = SinewaveGenerator()
gain = Gain(Bus())
mem = Memory(Bus(), 2, initial=rand(1))
writer = Writer(Bus())

connect(gen.output, gain.input)
connect(gain.output, mem.input)
connect(mem.output, writer.input)

model = Model(gen, mem, gain, writer)

sim = simulate(model, 0., 0.01, 1.)

t, x = read(writer, flatten=true)

display(plot(t, x))