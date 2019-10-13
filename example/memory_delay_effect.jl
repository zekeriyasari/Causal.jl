# This file illustrates the effect of Memory on simulation accuracy.

using Jusdl
using DifferentialEquations
using Plots 

# Test case parameters 
t0 = 0.
dt = 0.001  # INFO: Seems that for dt <= 0.001 the Jusdl performs as good as DifferentialEquations.
tf = 50.
x0 = [1.]
inputfunc = sin

# Solve the system using Jusdl 
gen = FunctionGenerator(inputfunc)
adder = Adder(Bus(2), (+, -))
ds = LinearSystem(Bus(1), Bus(1), state=x0, B=fill(1, 1, 1))
mem = Memory(Bus(1), 1, initial=ones(1) * 1000)
writer = Writer(Bus(1))
connect(gen.output, adder.input[1])
connect(adder.output, ds.input)
connect(ds.output, mem.input)
connect(mem.output, adder.input[2])
connect(ds.output, writer.input)
model = Model(gen, ds, adder, mem, writer)
sim = simulate(model, t0, dt, tf)
t, xj  = read(writer, flatten=true)

# Solve the system using DifferentialEquations
function f(dx, x, u, t)
    dx[1] = -2*x[1] + u(t)
end
tspan = (t0, tf)
sol = solve(ODEProblem(f, x0, tspan, inputfunc), saveat=dt)
xd = vcat(sol.u[1:length(xj)]...)


# Define the real solution
if inputfunc == zero
    xr = x0[1] * exp.(-2*t) 
elseif inputfunc == identity
    xr = (x0[1] + 1/4) * exp.(-2*t) + t/2 .- 1/4 
elseif  inputfunc == sin 
    xr = (x0[1] + 1/5) * exp.(-2*t) + (2 * sin.(t) - cos.(t)) / 5
else
    error("inputfunc is undefined.")
end

# Plot the results
p1 = plot(t, xj, label=:xj)
p2 = plot!(t, xr, label=:xr)
p3 = plot!(t, xd, label=:xd)
p4 = plot(t, abs.(xj - xr), label=:err_jusdl)
p5 = plot!(t, abs.(xd - xr), label=:err_diffeq)
plot(p3, p5, layout=(2,1))


