using Jusdl 
using Plots; pyplot()

function sf(dx, x, u, t)
    dx[1] = -x[1] + u[1](t)
end
of(x, u, t) = x
model = Model()
model[:gen] = SinewaveGenerator(frequency=2)
model[:adder] = Adder((+,-))
model[:ds] = ODESystem(sf, of, [1.], 0., Inport(), Outport())
model[:writer] = Writer()
model[:gen => :adder] = Indices(1 => 1)
model[:adder => :ds] = Indices(1 => 1)
model[:ds => :adder] = Indices(1 => 2)
model[:ds => :writer] = Indices(1 => 1)

simulate(model)

t, x = read(model[:writer].component)
plot(t, x)
