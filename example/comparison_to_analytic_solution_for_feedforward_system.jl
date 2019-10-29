using Jusdl 
using Plots 
using DifferentialEquations
using Interpolations

# Simualation settings 
t0, dt, tf = 0, 0.05, 50.
inputfunc = sin

# Solve the system using Jusdl
x0 = ones(1)
gen = FunctionGenerator(inputfunc)
ds = LinearSystem(Bus(1), Bus(1), state=x0, B=fill(1., 1, 1))
# ds.inputval .= inputfunc(t0)
writer = Writer(Bus(length(ds.output)))
connect(gen.output, ds.input)
connect(ds.output, writer.input)
model = Model(gen, ds, writer)
sim = simulate(model, t0, dt, tf)
t, xjusdl = read(writer, flatten=true)

# Solve the system using DifferentialEquations 
f(dx, x, u, t) = (dx[1] = -x[1] + u[1](t))
x = x0
statebuf = [x0]
interpolant = BSpline(Linear())
u0 = inputfunc(t0)
for t in dt : dt : tf
    global x, u0
    u1 = inputfunc(t)
    itp = scale(interpolate([u0, u1], interpolant), range(t - dt, t, length=2))
    sol = solve(ODEProblem(f, x, (t - dt, t), [itp]))
    x = sol.u[end]
    u0 = inputfunc(t)
    push!(statebuf, x)
end
xdiffeq = collect(hcat(statebuf...)')[1 : size(xjusdl,1), :]

# Define the analytic solution.
if gen.outputfunc == identity
    xanalytic = (x0[1] + 1) * exp.(-t) + t .- 1
elseif gen.outputfunc == sin 
    xanalytic = (x0[1] + 1 / 2) * exp.(-t) + (sin.(t) - cos.(t)) / 2
elseif gen.outputfunc == zero 
    xanalytic = x0[1] * exp.(-t)
end

# Compute the error.
err_analytic_jusdl = xanalytic - xjusdl
err_analytic_diffeq = xanalytic - xdiffeq
err_jusdl_diffeq = xjusdl - xdiffeq

# # Plot the results.
p1 = plot(t, xjusdl, label=:xjusdl)
    plot!(t, xdiffeq, label=:xdiffeq)
    plot!(t, xanalytic, label=:analytic)
p2 = plot(t, abs.(err_analytic_jusdl), label=:err_analytic_jusdl)
    plot!(t, abs.(err_analytic_diffeq), label=:err_analytic_diffeq)
p3 = plot(t, abs.(err_analytic_diffeq), label=:err_analytic_diffeq)
p4 = plot(t, abs.(err_jusdl_diffeq), label=:err_jusdl_diffeq)
display(plot(p1, p2, p3, p4))