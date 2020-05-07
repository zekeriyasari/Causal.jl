using Jusdl 
using Plots; pyplot()

# Construct a model 
model = Model(clock=Clock(0, 0.01, 10)) 
addcomponent(model, FunctionGenerator(one, name=:gen))
addcomponent(model, Adder(Inport(2), (+, -), name=:adder))
addcomponent(model, LinearSystem(Inport(), Outport(), B=fill(1, 1, 1), name=:ds))
addcomponent(model, Memory(Inport(), 2, name=:mem))
addcomponent(model, Writer(Inport(), name=:writer4))
addconnection(model, :gen, :adder, 1, 1)
addconnection(model, :adder, :ds)
addconnection(model, :ds, :mem)
addconnection(model, :mem, :adder, 1, 2)
addconnection(model, :ds, :writer4)

# Simulate the model 
sim = simulate!(model)

# Plots results
t, x = read(getcomponent(model, :writer4), flatten=true)
p = plot(t, x)
display(p)
