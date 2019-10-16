# This exampe illustrates the simulation of chaotic system with different time steps

using DifferentialEquations
using Plots 

# Simulation settings 
t0, dt, tf = 0., 0.01, 100.
x0 = rand(6)

# Define the system 
function f(dx, x, u, t, sigma=10, beta=8/3, rho=28, weight=10000.)
    dx[1] = sigma * (x[2] - x[1]) + weight * (x[4] - x[1])
    dx[2] = x[1] * (rho - x[3]) - x[2]
    dx[3] = x[1] * x[2] - beta * x[3]
    dx[4] = sigma * (x[5] - x[4]) + weight * (x[1] - x[4])
    dx[5] = x[4] * (rho - x[6]) - x[5]
    dx[6] = x[4] * x[5] - beta * x[6]
end

# Solve the system in steps 
buf = [x0]
x = x0 
for t in 0 : dt : tf
    global x 
    sol = solve(ODEProblem(f, x, (t, t + dt)), dt=1e-15)
    x = sol.u[end]
    push!(buf, x)
end
x = collect(hcat(buf...)')

# Plot the results 
p1 = plot(x[:, 1])
p2 = plot(x[:, 1], x[:, 2])
p3 = plot(abs.(x[:, 1] - x[:, 4]))
display(plot(p1, p2, p3, layout=(3,1)))
