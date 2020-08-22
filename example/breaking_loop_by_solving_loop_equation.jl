# This file includes an example file by breaking algebraic loops by solving loop equation numerically.

using Causal 
using Plots

# Simulation parameter
α = 3.

# Construct model with algebraic loop
@defmodel model begin 
    @nodes begin 
        gen = RampGenerator() 
        adder = Adder(signs=(+,-))
        gain = Gain(gain=α) 
        writer = Writer(input=Inport(2))
    end
    @branches begin 
        gen[1]      =>      adder[1]
        adder[1]    =>      gain[1]
        gain[1]     =>      adder[2]
        gen[1]      =>      writer[1] 
        gain[1]     =>      writer[2] 
    end
end

# Simulate the model
simulate!(model, 0., 1., 100.)

# Plot the results
t, y = read(getnode(model, :writer).component)
yt = α / (α + 1) * getnode(model, :gen).component.readout.(t)
err = yt - y[:, 2]
p1 = plot(t, y[:, 1], label=:u)
    plot!(t, y[:, 2], label=:y)
    plot!(t, yt, label=:true)
p2 = plot(t, err, label=:err)
plot(p1, p2, layout=(2, 1))
