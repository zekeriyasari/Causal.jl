# Simulation of coupled Lorenz systems.

using Jusdl 
using Plots; pyplot()

# Construct the model 
ε = 10.
model = Model(clock=Clock(0., 0.01, 100.)) 
model[:ds1] = LorenzSystem(Inport(3), Outport(3))
model[:ds2] = LorenzSystem(Inport(3), Outport(3))
model[:coupler] = Coupler(ε * [-1 1; 1 -1], [1 0 0; 0 0 0; 0 0 0])
model[:writer]  = Writer(Inport(6))
model[:ds1 => :coupler] = Indices(1:3 => 1:3)
model[:ds2 => :coupler] = Indices(1:3 => 4:6)
model[:coupler => :ds1] = Indices(1:3 => 1:3)
model[:coupler => :ds2] = Indices(4:6 => 1:3)
model[:ds1 => :writer] = Indices(1:3 => 1:3)
model[:ds2 => :writer] = Indices(1:3 => 4:6)

# Plot signal flow diagram of model 
display(signalflow(model))

# Simulate the model 
simulate(model)

# Plot signal flow diagram of model 
display(signalflow(model))

# Read simulation data 
t, x = read(model[:writer].component)

# Compute errors
err = x[:, 1] - x[:, 4]

# Plot the results.
p1 = plot(x[:, 1], x[:, 2])
p2 = plot(x[:, 4], x[:, 5])
p3 = plot(t, err)
display(plot(p1, p2, p3, layout=(3, 1)))
