# This file illustrate solution of dynamic systems with inputs in different time steps.

using DifferentialEquations
using Plots 
using ProgressMeter
using Interpolations
using LinearAlgebra

# Simulation settings 
t0, dt, tf = 0., 0.01, 20.
infunc = [sin]
x0 = rand(1)

# Define the system 
function f(dx, x, u, t)
    dx[1] = -x[1] + u[1](t)
end

# Solve system in steps by passing the input function.
x = x0
statebuf = [x0]
@showprogress dt  for t in dt : dt : tf 
    global  x
    sol = solve(ODEProblem(f, x, (t - dt, t), infunc))
    x = sol.u[end]
    push!(statebuf, x)
end
computedstates_with_input_function = collect(hcat(statebuf...)')

# Solve system in steps by passing the sampled function values
x = x0
statebuf = [x0]
@showprogress dt  for t in dt : dt : tf 
    global  x
    u = infunc[1](t)
    sol = solve(ODEProblem(f, x, (t - dt, t), [t -> u]))
    x = sol.u[end]
    push!(statebuf, x)
end
computedstates_with_sample_and_hold = collect(hcat(statebuf...)')

# Solve system in steps by passing the interpolated function values
x = x0
u1 = infunc[1](t0)  # When initial is not zero, error converges to zero.
statebuf = [x0]
interpolant = BSpline(Linear())
@showprogress dt for t in dt : dt : tf 
    global x
    global u0
    global u1
    u2 = infunc[1](t)
    itp = scale(interpolate([u1, u2],  interpolant), range(t - dt, t, length=2))
    sol = solve(ODEProblem(f, x, (t - dt, t), [itp]))
    x = sol.u[end]
    u1 = itp(t)
    push!(statebuf, x)
end
computedstates_with_linear_interpolation = collect(hcat(statebuf...)')

# Solve system in steps by passing the interpolated function values
x = x0
u0 = infunc[1](t0 - dt)  # When initial is not zero, error converges to zero.
u1 = infunc[1](t0)  # When initial is not zero, error converges to zero.
statebuf = [x0]
interpolant = BSpline(Quadratic(Line(OnGrid())))
@showprogress dt for t in dt : dt : tf 
    global x
    global u0
    global u1
    u2 = infunc[1](t)
    itp = scale(interpolate([u0, u1, u2],  interpolant), range(t - 2dt, t, length=3))
    sol = solve(ODEProblem(f, x, (t - dt, t), [itp]))
    x = sol.u[end]
    u1 = itp(t)
    u0 = itp(t - dt)
    push!(statebuf, x)
end
computedstates_with_quadratic_interpolation = collect(hcat(statebuf...)')

# Define real solution
t = collect(t0:dt:tf)
if infunc[1] == identity
    analyticalstates = (x0[1] + 1) * exp.(-t) + t .- 1
elseif infunc[1] == sin 
    analyticalstates = (x0[1] + 1 / 2) * exp.(-t) + (sin.(t) - cos.(t)) / 2
elseif infunc[1] == one
    analyticalstates = (x0[1] - 1) * exp.(-t) .+ 1
elseif infunc[1] == zero 
    analyticalstates = x0[1] * exp.(-t)
else
    analyticalstates = (x0[1] - 2) * exp.(-t) + t.^2 - 2t .+ 2
end

# Compute errors 
err_functional= abs.(computedstates_with_input_function - analyticalstates)
err_sample_and_hold = abs.(computedstates_with_sample_and_hold - analyticalstates)
err_linear_interpolation = abs.(computedstates_with_linear_interpolation - analyticalstates)
err_quadratic_interpolation = abs.(computedstates_with_quadratic_interpolation - analyticalstates)

@show norm(err_functional)
@show norm(err_sample_and_hold)
@show norm(err_linear_interpolation)
@show norm(err_quadratic_interpolation)

p1 = plot(t, analyticalstates, label=:analytical, ylabel=:state)
    plot!(t, computedstates_with_input_function, label=:functional)
    plot!(t, computedstates_with_sample_and_hold, label=:samplehold)
    plot!(t, computedstates_with_linear_interpolation, label=:linearinterp)
    plot!(t, computedstates_with_quadratic_interpolation, label=:quadraticinterp)
    
p2 = plot(t, err_functional, label=:functional, ylabel=:error)
    plot!(t, err_sample_and_hold, label=:samplehold)
    plot!(t, err_linear_interpolation, label=:linearinterp)
    plot!(t, err_quadratic_interpolation, label=:quadraticinterp)

p3 = plot(t, err_functional, label=:functional, ylabel=:error)
    plot!(t, err_linear_interpolation, label=:linearinterp)
    plot!(t, err_quadratic_interpolation, label=:quadraticinterp)

p4 = plot(t, err_functional, label=:functional, ylabel=:error)

display(plot(p1, p2, p3, p4, layout=(2, 2), size=(1000, 500)))