# This file illuustrates the simulation of coupled dynamical systems for different coupling configurations.

using Jusdl 
using Plots 
using DifferentialEquations

# Define the simulation settings 
t0 = 0.
dt = 0.001
tf = 50.
x0 = rand(6)
eps = 1.

# Simulate the system using Jusdl by constructing a network
numnodes = 5 
dimnodes = 3
conmat = [-eps eps 0 0 0; 
    eps -2eps eps 0 0; 
    0 eps -2eps eps 0;
    0 0 eps -eps 0;
    0 0 0 0 0]
net = Network(
    [LorenzSystem(Bus(dimnodes), Bus(dimnodes)) for i = 1 : numnodes],
    conmat, getcplmat(dimnodes, 1))
writer = Writer(Bus(length(net.output)))
connect(net.output, writer.input)
model = Model(net, writer)

sim = simulate(model, t0, dt, tf)
t, xj = read(writer, flatten=true)

# # Simuate the system using DifferentialEquations
# function f(dx, x, u, t, sigma=10, beta=8/3, rho=28, eps=eps)
#     dx[1] = sigma * (x[2] - x[1]) + eps * (x[4] - x[1])
#     dx[2] = x[1] * (rho - x[3]) - x[2]
#     dx[3] = x[1] * x[2] - beta * x[3]
#     dx[4] = sigma * (x[5] - x[4]) + eps * (x[1] - x[4])
#     dx[5] = x[4] * (rho - x[6]) - x[5]
#     dx[6] = x[4] * x[5] - beta * x[6]
# end
# tspan = (t0, tf)
# sol = solve(ODEProblem(f, x0, tspan), saveat=dt)
# xd = vcat(hcat(sol.u[1:size(xj, 1)]...)')

# # Compute the errors 
# errj = abs.(xj[:, 1] - xj[:, 4])
# errd = abs.(xd[:, 1] - xd[:, 4])

# Plot the results 
# p1 = plot(t, xj[:, 1], label=:xj1)
#     plot!(t, xd[:, 1], label=:xd1)
# p2 = plot(t, errj, label=:errj)
#     plot!(t, errd, label=:errd)
# p3 = plot(xj[:, 1], xj[:, 2], label=:trj)
# p4 = plot(xd[:, 1], xd[:, 2], label=:trd)
# display(plot(p1, p2, p3, p4, layout=(2,2)))

p1 = gplot(net)
p2 = plot(t, abs.(xj[:, 1] - xj[:, 4]), label=:errj)
    plot!(t, abs.(xj[:, 4] - xj[:, 7]), label=:errj)
    plot!(t, abs.(xj[:, 7] - xj[:, 10]), label=:errj)
    plot!(t, abs.(xj[:, 10] - xj[:, 13]), label=:errj)
display(p1)
display(p2)