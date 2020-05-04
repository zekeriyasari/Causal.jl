# This file simulates a closed system 

using Jusdl 

# Construct the model 
model = Model(clock=Clock(0, 0.01, 10.))
addnode(model, FunctionGenerator(sin), label=:gen)
addnode(model, Adder((+,-)), label=:adder)
addnode(model, ODESystem((dx,x,u,t)->(dx[1]=-x[1]+u[1](t)), (x,u,t) -> x, [1.], 0., Inport(), Outport()), label=:ds)
addnode(model, Writer(Inport(2)), label=:writer)
addbranch(model, :gen => :adder, 1 => 1)
addbranch(model, :adder => :ds, 1 => 1)
addbranch(model, :ds => :adder, 1 => 2)
addbranch(model, :gen => :writer, 1 => 1)
addbranch(model, :ds => :writer, 1 => 2)

# Simualate the model 
sim = simulate(model)

# Read and plot data 
t, x = read(getnode(model, :writer).component)
using Plots; pyplot()
plot(t, x[:, 1], label="r(t)", xlabel="t", lw=3)
plot!(t, x[:, 2], label="y(t)", xlabel="t", lw=3)
plot!(t, 6 / 5 * exp.(-2t) + 1 / 5 * (2 * sin.(t) - cos.(t)), label="Analytical Solution", lw=3)
fileanme = "readme_example.svg"
path = joinpath(@__DIR__, "../docs/src/assets/ReadMePlot/")
savefig(joinpath(path, fileanme))
