using Jusdl 
using Plots; pyplot()

# Construct the model 
α = 1
ti, dt, tf = 0., 1., 100.
model = Model(clock=Clock(ti, dt, tf)) 
model[:gen] = RampGenerator(scale=1)
model[:adder] = Adder((+,-))
model[:gain] = Gain(gain=α) 
model[:writer1] = Writer()
model[:writer2] = Writer()

model[:gen => :adder] = Edge(1 => 1)
model[:adder => :gain] = Edge(1 => 1)
model[:gain => :adder] = Edge(1 => 2)

model[:gen => :writer1] = Edge(1 => 1)
model[:adder => :writer2] = Edge(1 => 1)

simulate(model)

# Plot simulation data 
t, r = read(model[:writer1].component)
t, y = read(model[:writer2].component)

yreal = α / (α + 1) * model[:gen].component.outputfunc.(t)

marker = (:circle, 3)
n1, n2 = 1, 5
p = plot(t[n1:n2], r[n1:n2], label=:r, marker=marker)
    plot!(t[n1:n2], y[n1:n2], label=:y, marker=marker)
    plot!(t[n1:n2], yreal[n1:n2], label=:yreal, marker=marker, ls=:dot)
display(p)
