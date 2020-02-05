using Jusdl 
using Plots 

gen = SinewaveGenerator()
writer = Writer(Bus())
connect(gen.output, writer.input)
model = Model(gen, writer)
sim = simulate(model, 0., 0.01, 10.)