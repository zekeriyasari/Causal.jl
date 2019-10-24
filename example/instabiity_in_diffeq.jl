# This example illustrates the simuation of dynamic systems under coupling 
# If the input is kept constant during each step of the simulation, then 
# the coupling strengh should not be too much.

using DifferentialEquations
using Plots 

# Simulation settings 
t0, dt, tf = 0., 0.01, 100.
eps = 10.

# Define the system 
function f(dx, x, u, t, sigma=10, beta=8/3, rho=28)
    dx[1] = sigma * (x[2] - x[1]) + u[1]
    dx[2] = x[1] * (rho - x[3]) - x[2]
    dx[3] = x[1] * x[2] - beta * x[3]
    dx[4] = sigma * (x[5] - x[4]) + u[2]
    dx[5] = x[4] * (rho - x[6]) - x[5]
    dx[6] = x[4] * x[5] - beta * x[6]
end

# Solve the system in steps 
x = rand(6)
buf = []
inbuf = []
for t in t0 : dt : tf - dt
    global  x
    u = eps * [x[4] - x[1], x[1] - x[4]]
    sol = solve(ODEProblem(f, x, (t, t + dt), u))
    x = sol.u[end]
    push!(buf, x)
    push!(inbuf, u)
end

# Plot the results 
x = collect(hcat(buf...)')
u = collect(hcat(inbuf...)')
p1 = plot(x[:, 1])
    plot!(u[:, 1])
p2 = plot(x[:, 1], x[:, 2])
display(plot(p1, p2, layout=(2,1)))