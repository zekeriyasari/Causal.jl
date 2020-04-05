# This file simulates a closed system 

using Jusdl 

model = Model(clock=Clock(0, 0.01, 10.))
addcomponent(model, FunctionGenerator(sin, name=:gen))
addcomponent(model, Adder(Inport(2), (+,-), name=:adder))
addcomponent(model, ODESystem((dx,x,u,t)->(dx[1]=-x[1]+u[1](t)), (x,u,t) -> x, [1.], 0., Inport(), Outport(), name=:ds))
addcomponent(model, Memory(Inport(), 1, name=:mem))
addcomponent(model, Writer(Inport(2), name=:writer))
addconnection(model, :gen, :adder, 1, 1)
addconnection(model, :adder, :ds)
addconnection(model, :ds, :mem)
addconnection(model, :mem, :adder, 1, 2)
addconnection(model, :gen, :writer, 1, 1)
addconnection(model, :ds, :writer, 1, 2)

# Simualate the model 
sim = simulate(model)

# Read and plot data 
t, x = read(getcomponent(model, :writer), flatten=true)
using Plots 
plot(t, x[:, 1], label="r(t)", xlabel="t")
plot!(t, x[:, 2], label="y(t)", xlabel="t")
plot!(t, 6 / 5 * exp.(-2t) + 1 / 5 * (2 * sin.(t) - cos.(t)), label="Analytical Solution")
fileanme = "readme_example.svg"
path = joinpath(@__DIR__, "../docs/src/assets/ReadMe/")
savefig(joinpath(path, fileanme))
