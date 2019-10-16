# Solution of linear dynamic system with different step sizes.
# This example shows that solution of a chaotic system with different time step 
# results completely different trajectories.

using DifferentialEquations
using LinearAlgebra
using Plots; pyplot()

# Simulation settings 
t0 = 0.
tf = 100.
x0 = ones(3)

# Define the system 
function f(dx, x, u, t, sigma=10, beta=8/3, rho=28)
    dx[1] = sigma * (x[2] - x[1])
    dx[2] = x[1] * (rho - x[3]) - x[2]
    dx[3] = x[1] * x[2] - beta * x[3]
end

# Solve the system for large stepsize
dtl = 0.01
buf = [x0]
x = x0
for t in 0. : dtl : tf - dtl 
    global x
    sol = solve(ODEProblem(f, x, (t, t + dtl)))
    x = sol.u[end]
    push!(buf, x)
end
xl = collect(hcat(buf...)')

# Solve the system for smaller stepsize
dts = 0.005
buf = [x0]
x = x0
for t in 0. : dts : tf - dts 
    global x
    sol = solve(ODEProblem(f, x, (t, t + dts)))
    x = sol.u[end]
    push!(buf, x)
end
xs = collect(hcat(buf...)')

plot(collect(t0 : dts : tf), xs[:, 1], markershape=:circle, label=:smallstepsize)
plot!(collect(t0 : dtl : tf), xl[:, 1], markershape=:circle, label=:largestepsize)

