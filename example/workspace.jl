using Jusdl 
using Plots 

gen = SinewaveGenerator()
gain1 = Gain(Bus())
gain2 = Gain(Bus())
mem = Memory(Bus(), 50, initial=rand(1))
writer = Writer(Bus())

connect(gen.output, gain1.input)
connect(gain1.output, gain2.input)
connect(gain2.output, mem.input)
connect(mem.output, writer.input)

model = Model(gen, gain1, gain2, writer, mem)

sim = simulate(model, 0., 0.01, 10.)

t, x = read(writer, flatten=true)

display(plot(t,x ))
