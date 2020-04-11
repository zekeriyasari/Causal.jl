using Jusdl 
using Plots; pyplot()


model = Model(clock=Clock(0, 0.001, 1.)) 
model[:gen] = ConstantGenerator() 
model[:adder] = Adder((+,-))
model[:gain] = Gain(gain=0.2) 
model[:writer] = Writer(Inport(2))

model[:gen => :adder] = Edge(1 => 1)
model[:adder => :gain] = Edge(1 => 1)
model[:gain => :adder] = Edge(1 => 2)
model[:gain => :writer] = Edge(1 => 1)
model[:adder => :writer] = Edge(1 => 2)

simulate(model)

t, x = read(model[:writer].component, flatten=true)
p = plot()
# ylims!(0, 1)
n = 40
plot!(t[1:n], x[1:n, 1], label=:gain)
plot!(t[1:n], x[1:n, 2], label=:gen)
display(p)
