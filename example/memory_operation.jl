# This file includes an example of memory operation. 
# In this example `mem` delays its input for one step size time.

using Jusdl 
using Plots

# Construct a model
ti = 0
dt = 1
tf = 100.
numtaps = 5  # Number of buffer taps in Memory.
delay = dt   # One step size delay.
model = Model(clock=Clock(ti, dt, tf)) 
addnode!(model, RampGenerator(), label=:gen)
addnode!(model, Memory(delay, numtaps=numtaps, dt=dt), label=:mem)
addnode!(model, Writer(Inport(2)), label=:writer)
addbranch!(model, :gen => :mem, 1 => 1)
addbranch!(model, :mem => :writer, 1 => 1)
addbranch!(model, :gen => :writer, 1 => 2)
simulate!(model) 

# Read simulation data
t, x = read(getnode(model, :writer).component)
u = getnode(model, :gen).component.outputfunc.(t .- delay)
err = u - x[:, 2]

# Plots simulation data
n1, n2 = 1, 5
marker = (:circle, 2)
p1 = plot(t[n1:n2], x[n1:n2, 1], label=:mem, marker=marker)
plot!(t[n1:n2], x[n1:n2, 2], label=:gen, marker=marker)
plot!(t[n1:n2], u[n1:n2], label=:real, marker=marker)
p2 = plot(t[n1:n2], err[n1:n2], label=:error, marker=marker)
display(plot(p1, p2, layout=(2,1)))
