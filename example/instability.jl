# Thjs file illustrates the instabilty of solutions 

using DifferentialEquations
using Plots 

# Simulation settings 
t0, dt, tf = 0., 0.01, 10.
x0 = rand(1)

# Define the system 
function f(dx, x, u, t)
    dx .= 100t * x
    if any(isnan.(dx))      # When dx is NaN, throw error and terminate simulation.
        @show (dx, x, t)
        error()
    end
end

buf = [x0]
x = x0
for t in t0 : dt : tf - dt 
    global x
    sol = solve(ODEProblem(f, x, (t, t + dt)))
    x = sol.u[end]
    push!(buf, x)
end
