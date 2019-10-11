using Jusdl 
using Plots 

# Construct a subsystem
gain1 = Gain(Bus(), 2)
gain2 = Gain(Bus(), 4)
connect(gain1.output, gain2.input)
sub = SubSystem([gain1, gain2], gain1.input, gain2.output)

# Construct a source and a sink.
gen = FunctionGenerator(sin)
writer = Writer(Bus())

# Connect the source, subsystem and sink.
connect(gen.output, sub.input)
connect(sub.output, writer.input)

# # Construct the model 
model = Model(gen, sub, writer)

# Simulate the model 
sim = simulate(model, 0, 0.01, 10)

# Read and plot simulation data 
content = read(writer)
t = vcat(collect(keys(content))...)
x = vcat(vcat(collect(values(content))...)...)
plot(t, x)
