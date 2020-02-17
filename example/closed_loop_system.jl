# This file simulates a closed system 

using Jusdl 

# Construct a model 
gen = FunctionGenerator(sin)
adder = Adder(Bus(2), (+, -))
ds = ODESystem(Bus(1), Bus(1), (dx,x,u,t) -> (dx[1] = -x[1] + u[1](t)), (x,u,t) -> x, [1.], 0.)
mem = Memory(Bus(1), 1)
writer = Writer(Bus(2)) 
connect(gen.output, adder.input[1])
connect(adder.output, ds.input)
connect(ds.output, mem.input)
connect(mem.output, adder.input[2])
connect(gen.output, writer.input[1])
connect(ds.output, writer.input[2])
model = Model(gen, mem, adder, ds, writer)

# Simualate the model 
tinit, tsample, tfinal = 0, 0.01, 10.
sim = simulate(model, tinit, tsample, tfinal)

# Read and plot data 
t, x = read(writer, flatten=true)
using Plots 
plot(t, x[:, 1], label="r(t)", xlabel="t")
plot!(t, x[:, 2], label="y(t)", xlabel="t")
plot!(t, 6 / 5 * exp.(-2t) + 1 / 5 * (2 * sin.(t) - cos.(t)), label="Analytical Solution")
fileanme = "readme_example.svg"
path = joinpath(@__DIR__, "../docs/src/assets/ReadMe/")
savefig(joinpath(path, fileanme))
