using Jusdl
using Plots

# Construct the model
@defmodel model begin
    @nodes begin 
        ds = ChenSystem() 
        writer = Writer(input=Inport(3)) 
    end
    @branches begin 
        ds[1:3] => writer[1:3]
    end
end

# Simulate the model 
simulate!(model, 0, 0.01, 100.)

# Plot results 
t, x = read(getnode(model, :writer).component)
plots = [
    plot(t, x[:, 1], label=:x1),
    plot(t, x[:, 2], label=:x1),
    plot(t, x[:, 3], label=:x1),
    plot(x[:, 1], x[:, 2], label=:x1x2),
    plot(x[:, 1], x[:, 3], label=:x1x3),
    plot(x[:, 2], x[:, 3], label=:x2x3)
    ]
display(plot(plots...))