# This example simulates a Folded map
using JuSDL
using Plots 

# Construct the components 
function statefunc(dx, x, u, t, a=-0.1, b=-1.7)
    dx[1] = x[2] + a * x[1]
    dx[2] = b + x[1]^2
end
outputfunc(x, u, t) = x
ds = DiscreteSystem(statefunc, outputfunc, rand(2), 0)
writer = Writer(Bus(2))
clk = Clock(0., 1., 10000.)

# Connect the components
connect(ds.output, writer.input)

# Construct the model 
model = Model(ds, writer, clk=clk)
 
# Simualate the model 
sim = simulate(model)

# Read back simulation data
data = vcat(collect(values(read(writer)))...)

# Plot the data
scatter(data[:, 1], data[:, 2], ms=0.25)


