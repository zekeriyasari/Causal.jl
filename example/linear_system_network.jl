# This file illuustrates the simulation of coupled dynamical systems 
using Jusdl 
using Plots 
using DifferentialEquations

# Define the simulation settings 
t0 = 0.
dt = 0.001
tf = 10.
x0 = [1., 2.] 
eps = 1

# Simulate the system using Jusdl by constructing a network
net = Network(
    [LinearSystem(Bus(1), Bus(1), state=x0[1, :], B=fill(1, 1, 1)), 
    LinearSystem(Bus(1), Bus(1), state=x0[2, :], B=fill(1, 1, 1))],
    [-eps eps; eps -eps], fill(1, 1, 1))
writer = Writer(Bus(length(net.output)))
connect(net.output, writer.input)
model = Model(net, writer)

sim = simulate(model, t0, dt, tf)
t, xj = read(writer, flatten=true)

# Simuate the system using DifferentialEquations
function f(dx, x, u, t, eps=eps)
    dx[1] = -x[1] + eps * (x[2] - x[1])
    dx[2] = -x[2] + eps * (x[1] - x[2])
end
tspan = (t0, tf)
sol = solve(ODEProblem(f, x0, tspan), saveat=dt)
xd = vcat(hcat(sol.u[1:size(xj, 1)]...)')

# Define real solution 
xr = hcat((x0[1] - x0[2]) / 2 * exp.((-1 - 2 * eps) * t) + (x0[1] + x0[2]) / 2 * exp.(-1 * t),
    (-x0[1] + x0[2]) / 2 * exp.((-1 - 2 * eps) * t) + (x0[1] + x0[2]) / 2 * exp.(-1 * t))

# Compute the errors 
errj = abs.(xj - xr)
errd = abs.(xd - xr)

# Plot the results 
p1 = plot(t, xj[:, 1], label=:xj1)
plot!(t, xd[:, 1], label=:xd1)
plot!(t, xr[:, 1], label=:xr1)
p2 = plot(t, xj[:, 2], label=:xj2)
plot!(t, xd[:, 2], label=:xd2)
plot!(t, xr[:, 2], label=:xr2)
p3 = plot(t,  errj[:, 1], label=:errj1)
plot!(t,  errd[:, 1], label=:errd1)
p4 = plot(t,  errj[:, 2], label=:errj2)
plot!(t,  errd[:, 2], label=:errd2)
display(plot(p1, p2, p3, p4, layout=(2,2)))