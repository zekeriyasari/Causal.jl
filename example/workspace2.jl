using Jusdl 
using Plots 

gen1 = FunctionGenerator(sin)
gen2 = FunctionGenerator(sin)
adder = Adder(Bus(2))
gain = Gain(Bus(), 2)
writer = Writer(Bus())
connect(gen1.output, adder.input[1])
connect(gen2.output, adder.input[2])
connect(adder.output, gain.input)
connect(gain.output, writer.input)

model = Model(gen1, gen2, adder, gain, writer)

sim = simulate(model, 0, 0.01, 10)

content = read(writer)
t = vcat(collect(keys(content))...)
x = vcat(vcat(collect(values(content))...)...)
plot(t, x)

# sub = SubSystem([adder, gain], adder.input, gain.output)
# t1 = launch(sub)
# t2 = launch(sub.input, [[rand() for i in 1 : 10] for j in 1 : length(adder.input)])
# t3 = launch(sub.output)
