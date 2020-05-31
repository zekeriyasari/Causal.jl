# Simulation of coupled Lorenz systems.

using Jusdl 
using Plots

# Construct the model 
ε = 10.

@defmodel model begin 
    @nodes begin 
        ds1 = ForcedLorenzSystem() 
        ds2 = ForcedLorenzSystem() 
        coupler = Coupler(conmat = ε*[-1. 1; 1 -1], cplmat=[1. 0 0; 0 0 0; 0 0 0])
        writer = Writer(input=Inport(6))
    end
    @branches begin 
        ds1[1:3]        =>      coupler[1:3]
        ds2[1:3]        =>      coupler[4:6]
        coupler[1:3]    =>      ds1[1:3]
        coupler[4:6]    =>      ds2[1:3]
        ds1[1:3]        =>      writer[1:3]
        ds2[1:3]        =>      writer[4:6]
    end
end

# Plot signal flow diagram of model 
display(signalflow(model))

# Simulate the model 
simulate!(model, 0., 0.01, 100)

# Plot signal flow diagram of model 
display(signalflow(model))

# Read simulation data 
t, x = read(getnode(model, :writer).component)

# Compute errors
err = x[:, 1] - x[:, 4]

# Plot the results.
p1 = plot(x[:, 1], x[:, 2])
p2 = plot(x[:, 4], x[:, 5])
p3 = plot(t, err)
display(plot(p1, p2, p3, layout=(3, 1)))
