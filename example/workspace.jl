using Jusdl 
using Plots; pyplot()

model = Model()
model[:gen] = SinewaveGenerator(frequency=2)
model[:adder] = Adder((+,-))
model[:ds] = LinearSystem(A=fill(1, 1, 1), B=fill(1, 1, 1), C=fill(1, 1, 1), D=fill(1, 1, 1)) 
model[:writer] = Writer()
model[:gen => :adder] = Indices(1 => 1)
model[:adder => :ds] = Indices(1 => 1)
model[:ds => :adder] = Indices(1 => 2)
model[:ds => :writer] = Indices(1 => 1)

simulate(model)

t, x = read(model[:writer].component)
plot(t, x)

# using Interpolations
# using Plots; pyplot() 

# f(t) = sin(2 * pi * t)
# t = 0:0.5:1.
# x = f.(t)
# marker = (:circle, 3)
# plot(t, x, marker=marker)
# itp = CubicSplineInterpolation(t, x)
# tt = collect(0:0.01:t[end])
# plot!(tt, itp.(tt))

