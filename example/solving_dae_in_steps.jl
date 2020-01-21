# This file investigates the simulation of DAESystems in steps

using DifferentialEquations
using Sundials
using Plots

# Define problem function 
function statefunc(out, dx, x, u, t)
    out[1] = - 0.04x[1]              + 1e4*x[2]*x[3] - dx[1]
    out[2] = + 0.04x[1] - 3e7*x[2]^2 - 1e4*x[2]*x[3] - dx[2]
    out[3] = x[1] + x[2] + x[3] - 1.0
end

# Define initial conditions 
x0 = [1, 0., 0.]
dx0 = [-0.04, 0.04, 0.]
differential_vars = [true, true, false]
alg = IDA()

# Solve the system at once 
tspan = (0., 100000.)
prob = DAEProblem(statefunc, dx0, x0, tspan, differential_vars=differential_vars)
sol = solve(prob, alg, saveat=0.01)
datafull = collect(hcat(sol.u...)')

# Solve the system in different windows 
vals = []
ts = []
x = x0 
dx = dx0
for t in 0. : 100000. : 900000.
    global x
    tspan =  (t, t + 100000)
    prob = DAEProblem(statefunc, dx, x, tspan, differential_vars=differential_vars)
    sol = solve(prob, alg)
    push!(vals, sol.u)
    push!(ts, sol.t)
    x = sol.u[end]
    @show t 
end
t = vcat(ts...)
datasteps = collect(hcat(vcat(vals...)...)')


# Plot the results 
err = abs.(datafull - datasteps)
plt = plot(sol.t, datafull[:, 1])
    plot!(t , datasteps[:, 1])
plt2 = plot(t, err[:, 1])
display(plt)



