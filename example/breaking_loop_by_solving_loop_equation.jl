# This file includes an example file by breaking algebraic loops by solving loop equation numerically.

using Jusdl 
using Plots; pyplot()

# Construct model with algebraic loop
α = 3
model = Model(clock=Clock(0, 1, 100)) 
addnode!(model, RampGenerator(), label=:gen)
addnode!(model, Adder((+,-)), label=:adder)
addnode!(model, Gain(gain=α), label=:gain)
addnode!(model, Writer(Inport(2)), label=:writer)
addbranch!(model, :gen => :adder, 1 => 1)
addbranch!(model, :adder => :gain, 1 => 1)
addbranch!(model, :gain => :adder, 1 => 2)
addbranch!(model, :gen => :writer, 1 => 1)
addbranch!(model, :gain => :writer, 1 => 2)

# Simulate the model
simulate!(model)

# Plot the results
t, y = read(getnode(model, :writer).component)
yt = α / (α + 1) * getnode(model, :gen).component.outputfunc.(t)
err = yt - y[:, 2]
p1 = plot(t, y[:, 1], label=:u)
    plot!(t, y[:, 2], label=:y)
    plot!(t, yt, label=:true)
p2 = plot(t, err, label=:err)
plot(p1, p2, layout=(2, 1))
