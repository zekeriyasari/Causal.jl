# This file includes an example of memory operation. 

using Jusdl 
using Plots; pyplot()

# Construct a model
ti = 0
dt = 1
tf = 100.
numtaps = 5
delay = dt/100   # Amount of delay is less than step size. So extrapolation is used.
model = Model(clock=Clock(ti, dt, tf)) 
model[:gen] = RampGenerator()
model[:mem] = Memory(delay, numtaps=numtaps, dt=dt, t0=ti) 
model[:gain] = Gain() 
model[:writer] = Writer(Inport(2)) 
model[:gen => :mem] = Indices(1 => 1)
model[:mem => :gain] = Indices(1 => 1)
model[:gen => :writer] = Indices(1 => 1)
model[:gain => :writer] = Indices(1 => 2)
simulate(model) 

# Read simulation data
t, x = read(model[:writer].component)
u = model[:gen].component.outputfunc.(t .- delay)
err = u - x[:, 2]

# Plots simulation data
n1, n2 = 1, 5
marker = (:circle, 2)
p1 = plot(t[n1:n2], x[n1:n2, 1], label=:gen, marker=marker)
plot!(t[n1:n2], x[n1:n2, 2], label=:mem, marker=marker)
plot!(t[n1:n2], u[n1:n2], label=:real, marker=marker)
p2 = plot(t[n1:n2], err[n1:n2], label=:error, marker=marker)
display(plot(p1, p2, layout=(2,1)))
