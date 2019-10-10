using Jusdl 
using Plots 

gen1 = SinewaveGenerator()
gen2 = SinewaveGenerator()
adder = Adder(Bus(2))
gain = Gain(Bus(), 2)
subsystem = SubSystem([adder, gain], adder.input, gain.output)
writer = Writer(Bus())

connect(gen1.output, subsystem.input[1])
connect(gen2.output, subsystem.input[2])
connect(subsystem.output, writer.input)

model = Model(gen1, gen2, subsystem, writer)

sim = simulate(model, 0, 0.01, 10)

content = read(writer) 
t = vcat(collect(keys(content))...)
x = vcat(vcat(collect(values(content))...)...)
plot(t, x)
