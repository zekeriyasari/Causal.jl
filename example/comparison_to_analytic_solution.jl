using Jusdl 
using Plots 

# Simualation settings 
t0, dt, tf = 0, 0.01, 10.

# Construct the blocks
x0 = rand(1)
gen = FunctionGenerator(identity)
ds = LinearSystem(Bus(1), Bus(1), state=x0, B=fill(1., 1, 1))
mem = Memory(Bus(length(ds.output)), 1, initial=x0)
adder = Adder(Bus(length(gen.output) + length(mem.output)), (+, -))
writergenout = Writer(Bus(length(gen.output)))
writerdsout = Writer(Bus(length(ds.output)))
writermemout = Writer(Bus(length(mem.output)))
writeradderoutput = Writer(Bus(length(adder.output)))

# Connect the blocks 
connect(gen.output, adder.input[1])
connect(adder.output, ds.input)
connect(ds.output, mem.input)
connect(mem.output, adder.input[2])
connect(gen.output, writergenout.input)
connect(adder.output, writeradderoutput.input)
connect(ds.output, writerdsout.input)
connect(mem.output, writermemout.input)

# Construct the model
model = Model(gen, ds, adder, mem, writeradderoutput, writergenout, writerdsout, writermemout)

# Simuate the model 
sim = simulate(model, t0, dt, tf)

# Read the simulation data.
t, r = read(writergenout, flatten=true)
t, u = read(writeradderoutput, flatten=true)
t, x = read(writerdsout, flatten=true)
t, y = read(writermemout, flatten=true)

# Define the analytic solution.
if gen.outputfunc == identity
    xr = (x0[1] + 1 / 4) * exp.(-2 * t) + t / 2 .- 1 / 4
elseif gen.outputfunc == sin 
    xr = (x0[1] + 1 / 5) * exp.(-2 * t) + (2 * sin.(t) - cos.(t)) / 5
elseif gen.outputfunc == zero 
    xr = x0[1] * exp.(-2 * t)
end

# Compute the error.
err = xr - x

# Plot the results.
p1 = plot(t, x, label=:x)
    plot!(t, y, label=:xd)
    plot!(t, xr, label=:xr)
p2 = plot(t, abs.(err), label=:error)
display(plot(p1, p2, layout=(2,1)))