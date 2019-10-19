# This file illuustrates the simulation of coupled dynamical systems 
using Jusdl 
using Plots 
using DifferentialEquations

# Define the simulation settings 
t0, dt, tf = 0., 0.01, 10.
x0 = [1., 2.] 
eps = 1

# # Simulate the system using Jusdl by constructing explicite blocks
ds1 = LinearSystem(Bus(1), Bus(1), state=x0[1, :], B=fill(1, 1, 1))
ds2 = LinearSystem(Bus(1), Bus(1), state=x0[2, :], B=fill(1, 1, 1))
coupler = Coupler([-eps eps; eps -eps], fill(1, 1, 1))
mem1 = Memory(Bus(1), 1, initial=ones(1))
mem2 = Memory(Bus(1), 1, initial=ones(1))
writer = Writer(Bus(2))
connect(ds1.output, coupler.input[1])
connect(coupler.output[1], mem1.input)
connect(mem1.output, ds1.input)
connect(ds2.output, coupler.input[2])
connect(coupler.output[2], mem2.input)
connect(mem2.output, ds2.input)
connect(ds1.output, writer.input[1])
connect(ds2.output, writer.input[2])

model = Model(ds1, ds2, coupler, mem1, mem2, writer)

sim = simulate(model, t0, dt, tf)
t, x = read(writer, flatten=true)

# Define real solution 
xr = hcat((x0[1] - x0[2]) / 2 * exp.((-1 - 2 * eps) * t) + (x0[1] + x0[2]) / 2 * exp.(-1 * t),
    (-x0[1] + x0[2]) / 2 * exp.((-1 - 2 * eps) * t) + (x0[1] + x0[2]) / 2 * exp.(-1 * t))

# Compute the errors 
err = abs.(x - xr)

ni = 50 
nf = ni + 100
plot(x[ni:nf, 1], marker=(:circle, 1))
plot!(xr[ni:nf, 1], marker=(:circle, 1))
scatter(x[:, 1], x[:, 2], marker=(:circle, 1))
