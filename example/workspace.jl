
using Jusdl 
using Plots 

gen = SinewaveGenerator(1., 1. / 0.64)
mem = Memory(Bus(), 100, [0.])
writer = Writer(Bus())

connect(gen.output, mem.input)
connect(mem.output, writer.input)
model = Model(gen, writer, mem)

sim = simulate(model, 0., 0.01, 5.)

content = read(writer)
vals = vcat(vcat(collect(values(content))...)...)
t = vcat(collect(keys(content))...)
plot(t, vals)
