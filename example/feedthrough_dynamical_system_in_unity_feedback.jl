# This file illustrates the simulation of feedthrough dynamical system in a unity feedback.

using Jusdl 
using Plots; pyplot()

# Construct the model 
x0 = ones(1)
model = Model(clock=Clock(0., 0.01, 10.)) 
model[:gen] = FunctionGenerator(sin)
model[:adder] = Adder((+, -))
model[:ds] = LinearSystem(Inport(), Outport(), A=fill(-1,1,1), B=fill(1,1,1), C=fill(1,1,1), D=fill(1,1,1), state=x0)
model[:writer] = Writer()

model[:gen => :adder] = Indices(1 => 1)
model[:adder => :ds] = Indices(1 => 1)
model[:ds => :adder] = Indices(1 => 2)
model[:ds => :writer] = Indices(1 => 1)

# Simulate the model 
simulate!(model)

# Read simulation data
t, ys = read(model[:writer].component)

# Compoute simulation error
r = model[:gen].component.outputfunc.(t)
xa = (x0[1] + 2 / 13) * exp.(-3 / 2 * t) + 3 / 13 * sin.(t) - 2 / 13 * cos.(t)
ya = (xa + r) / 2
er = ys - ya

# Plot results.
p1 = plot(t, ys, label=:simulation)
    plot!(t, ya, label=:analytic)
p2 = plot(t, er, label=:error)
display(plot(p1, p2, layout=(2, 1)))
