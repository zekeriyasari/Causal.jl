using DifferentialEquations
using Plots 

# Simulation settings 
t0, dt, tf = 0., 0.01, 100.

# Define the system 
inbuf1 = []
inbuf2 = []
function f(dx, x, u, t, sigma=10, beta=8/3, rho=28, eps=10000)
    u1 = eps * (x[4] - x[1])
    u2 = eps * (x[1] - x[4])
    dx[1] = sigma * (x[2] - x[1]) + u1
    dx[2] = x[1] * (rho - x[3]) - x[2]
    dx[3] = x[1] * x[2] - beta * x[3]
    dx[4] = sigma * (x[5] - x[4]) + u2
    dx[5] = x[4] * (rho - x[6]) - x[5]
    dx[6] = x[4] * x[5] - beta * x[6]
    push!(inbuf1, u1)
    push!(inbuf2, u2)
end

# Solve the system in steps 
x = rand(6)
buf = []
for t in t0 : dt : tf - dt
    global  x
    sol = solve(ODEProblem(f, x, (t, t + dt)))
    x = sol.u[end]
    push!(buf, x)
end

# Plot the results 
x = collect(hcat(buf...)')
plot(x[:, 1])
plot(x[:, 1], x[:, 2])
plot(abs.(x[:, 1] - x[:, 4]))