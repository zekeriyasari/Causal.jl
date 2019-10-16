# This file illustrates the effect of sampling on the accuracy of Jusdl

using Jusdl
using DifferentialEquations
using Plots 

# Test case parameters 
t0 = 0.
dt = 0.001  # INFO: Seems that for dt <= 0.001 the Jusdl performs as good as DifferentialEquations.
tf = 10.
x0 = [1.]
inputfunc = one


# Solve the system using Jusdl 
gen = FunctionGenerator(inputfunc)
ds = LinearSystem(Bus(1), Bus(1), state=x0, B=fill(1, 1, 1))
writer = Writer(Bus(1))
connect(gen.output, ds.input)
connect(ds.output, writer.input)
model = Model(gen, ds, writer)
sim = simulate(model, t0, dt, tf)
t, xj  = read(writer, flatten=true)

# Define the real solution
if inputfunc == zero
    xr = x0[1] * exp.(-t) 
elseif inputfunc == identity
    xr = (x0[1] + 1) * exp.(-t) + t .- 1 
elseif  inputfunc == sin 
    xr = (x0[1] + 1 / 2) * exp.(-t) + (sin.(t) - cos.(t)) / 2
else
    error("inputfunc is undefined.")
end

# Solve the system using DifferentialEquations
function f(dx, x, u, t)
    dx[1] = -x[1] + u(t)
end
tspan = (t0, tf)
sol = solve(ODEProblem(f, x0, tspan, inputfunc), saveat=dt)
xd = vcat(sol.u[1:length(xj)]...)


# Plot the results
p1 = plot(t, xj, label=:xj)
p2 = plot!(t, xr, label=:xr)
p3 = plot!(t, xd, label=:xd)
p4 = plot(t, abs.(xj - xr), label=:err_jusdl)
p5 = plot!(t, abs.(xd - xr), label=:err_diffeq)
plot(p3, p5, layout=(2,1))


