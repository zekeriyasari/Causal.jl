# Simulation of coupled Lorenz systems.

using Jusdl 
using Plots; pyplot()

# Construct the model 
ε = 10.
model = Model(clock=Clock(0., 0.01, 100.)) 
addnode!(model, LorenzSystem(Inport(3), Outport(3)), label=:ds1)
addnode!(model, LorenzSystem(Inport(3), Outport(3)), label=:ds2)
addnode!(model, Coupler(ε * [-1 1; 1 -1], [1 0 0; 0 0 0; 0 0 0]), label=:coupler)
addnode!(model,  Writer(Inport(6)), label=:writer)
addbranch!(model, :ds1 => :coupler, 1:3 => 1:3)
addbranch!(model, :ds2 => :coupler, 1:3 => 4:6)
addbranch!(model, :coupler => :ds1, 1:3 => 1:3)
addbranch!(model, :coupler => :ds2, 4:6 => 1:3)
addbranch!(model, :ds1 => :writer, 1:3 => 1:3)
addbranch!(model, :ds2 => :writer, 1:3 => 4:6)

# Plot signal flow diagram of model 
display(signalflow(model))

# Simulate the model 
simulate!(model)

# Plot signal flow diagram of model 
display(signalflow(model))

# Read simulation data 
t, x = read(getnode(model, :writer).component)

# Compute errors
err = x[:, 1] - x[:, 4]

# Plot the results.
p1 = plot(x[:, 1], x[:, 2])
p2 = plot(x[:, 4], x[:, 5])
p3 = plot(t, err)
display(plot(p1, p2, p3, layout=(3, 1)))
