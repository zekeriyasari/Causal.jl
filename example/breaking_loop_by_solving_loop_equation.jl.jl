# This file includes an example file by breaking algebraic loops by solving loop equation numerically.

using Jusdl 
using Plots; pyplot()

# Construct model with algebraic loop
α = 3
model = Model(clock=Clock(0, 1, 100)) 
model[:gen] = RampGenerator()
model[:adder] = Adder((+,-))
model[:gain] = Gain(gain=α)
model[:writer] = Writer(Inport(2))
model[:gen => :adder] = Edge(1 => 1) 
model[:adder => :gain] = Edge(1 => 1) 
model[:gain => :adder] = Edge(1 => 2) 
model[:gen => :writer] = Edge(1 => 1)
model[:gain => :writer] = Edge(1 => 2)

# Simulate the model
simulate(model)

# Plot the results
t, y = read(model[:writer].component)
yt = α / (α + 1) * model[:gen].component.outputfunc.(t)
err = yt - y[:, 2]
p1 = plot(t, y[:, 1], label=:u)
    plot!(t, y[:, 2], label=:y)
    plot!(t, yt, label=:true)
p2 = plot(t, err, label=:err)
plot(p1, p2, layout=(2, 1))
