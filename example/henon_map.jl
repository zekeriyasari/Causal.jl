# This example simulates a Henon map

using JuSDL
using Plots 

# Construct the components 
# function statefunc(dx, x, u, t, alpha=1.07, beta=0.3)
#     dx[1] = -beta * x[2]
#     dx[2] = x[3] + 1 - alpha * x[2]^2 
#     dx[3] = beta * x[2] + x[1]
# end
function statefunc(dx, x, u, t, alpha=1.07, beta=0.3)
    dx[1] = 0.5*x[1]
    dx[2] = 0.5*x[2]
    dx[3] = 0.5*x[3]
end
outputfunc(x, u, t) = x
ds = DiscreteSystem(statefunc, outputfunc, rand(3), 0)
writer = Writer(Bus(3))
clk = Clock(0., 1., 10000.)

# Connect the components
connect(ds.output, writer.input)

# Construct the model 
model = Model(ds, writer, clk=clk)

# Simualate the model 
sim = simulate(model)
