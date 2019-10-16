# Solution of linear dynamic system with different step sizes.

using DifferentialEquations
using LinearAlgebra
using Plots; pyplot()


# Simulation settings 
t0 = 0.
tf = 100.
x0 = ones(3)

# Define the system 
function f(dx, x, u, t, A=-1 * Matrix{Float64}(I, 3,3))
    dx .= A * x + map(f -> f(t), u)
end

# Solve the system for large stepsize
dtl = 0.01
buf = [x0]
x = x0
for t in 0. : dtl : tf - dtl 
    global x
    sol = solve(ODEProblem(f, x, (t, t + dtl), [sin, sin, sin]))
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
    sol = solve(ODEProblem(f, x, (t, t + dts), [sin, sin, sin]))
    x = sol.u[end]
    push!(buf, x)
end
xs = collect(hcat(buf...)')

plot(collect(t0 : dtl : tf), xl[:, 1], markershape=:circle)
plot!(collect(t0 : dts : tf), xs[:, 1], markershape=:circle)

