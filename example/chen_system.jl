using Jusdl
using Plots; pyplot()

# Construct the model 
model = Model(clock=Clock( 0., 0.001, 100.))
addcomponent(model, ChenSystem(nothing, Outport(3), name=:ds))
addcomponent(model, Writer(Inport(3), name=:writer))
addconnection(model, :ds, :writer)

# Simulate model 
sim = simulate!(model)

# Plot results 
t, x = read(getcomponent(model, :writer), flatten=true)
plots = [
    plot(t, x[:, 1], label=:x1),
    plot(t, x[:, 2], label=:x1),
    plot(t, x[:, 3], label=:x1),
    plot(x[:, 1], x[:, 2], label=:x1x2),
    plot(x[:, 1], x[:, 3], label=:x1x3),
    plot(x[:, 2], x[:, 3], label=:x2x3)
    ]
display(plot(plots...))