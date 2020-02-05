using Jusdl 
using Plots 

ds = LinearSystem(nothing, Bus())
writer = Writer(Bus(3))

connect(ds.output, writer.input)

model = Model(ds, writer)

sim = simulate(model, 0., 0.01, 100.)

t, x = read(writer, flatten=true)

p1 = plot(t, x)
display(p1)
