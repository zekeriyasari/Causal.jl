# This file illustrates the simulation of feedthrough dynamical system in a unity feedback.

using Jusdl 
using Plots

# Construct the model 
x0 = ones(1)

@defmodel model begin
    @nodes begin 
        gen = FunctionGenerator(readout=sin)
        adder = Adder(signs=(+,-))
        ds = ContinuousLinearSystem(state=x0)
        writer = Writer()
    end
    @branches begin 
        gen[1]      =>      adder[1]
        adder       =>      ds
        ds[1]       =>      adder[2]
        ds          =>      writer
    end
end

# Simulate the model 
simulate!(model, 0., 0.01, 10.)

# Read simulation data
t, ys = read(getnode(model, :writer).component)

# Compoute simulation error
r = getnode(model,:gen).component.readout.(t)
xa = (x0[1] + 2 / 13) * exp.(-3 / 2 * t) + 3 / 13 * sin.(t) - 2 / 13 * cos.(t)
ya = (xa + r) / 2
er = ys - ya

# Plot results.
p1 = plot(t, ys, label=:simulation)
    plot!(t, ya, label=:analytic)
p2 = plot(t, er, label=:error)
display(plot(p1, p2, layout=(2, 1)))
