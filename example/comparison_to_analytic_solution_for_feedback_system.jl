# using Jusdl 
# using Plots 
# using DifferentialEquations
# using Interpolations

# # Simualation settings 
# t0, dt, tf = 0, 0.001, 10.
# inputfunc = zero

# # Solve the system using Jusdl
# x0 = ones(1)
# gen = FunctionGenerator(inputfunc)
# ds = LinearSystem(Bus(1), Bus(1), state=x0, B=fill(1., 1, 1))
# # ds.inputval .= inputfunc(t0) - ds.state[1]
# mem = Memory(Bus(length(ds.output)), 1, initial=x0)
# adder = Adder(Bus(length(gen.output) + length(mem.output)), (+, -))
# writer = Writer(Bus(length(ds.output)))
# connect!(gen.output, adder.input[1])
# connect!(adder.output, ds.input)
# connect!(ds.output, mem.input)
# connect!(mem.output, adder.input[2])
# connect!(ds.output, writer.input)
# model = Model(gen, ds, adder, mem, writer)
# sim = simulate!(model, t0, dt, tf)
# t, xjusdl = read(writer, flatten=true)

# # Solve the system using DifferentialEquations 
# f(dx, x, u, t) = (dx[1] = -2x[1] + u[1](t))
# x = x0
# statebuf = [x0]
# interpolant = BSpline(Linear())
# u0 = inputfunc(t0)
# for t in dt : dt : tf
#     global x, u0
#     u1 = inputfunc(t)
#     itp = scale(interpolate([u0, u1], interpolant), range(t - dt, t, length=2))
#     sol = solve(ODEProblem(f, x, (t - dt, t), [itp]))
#     x = sol.u[end]
#     u0 = inputfunc(t)
#     push!(statebuf, x)
# end
# xdiffeq = collect(hcat(statebuf...)')[1 : size(xjusdl,1), :]

# # Define the analytic solution.
# if gen.outputfunc == identity
#     xanalytic = (x0[1] + 1 / 4) * exp.(-2 * t) + t / 2 .- 1 / 4
# elseif gen.outputfunc == sin 
#     xanalytic = (x0[1] + 1 / 5) * exp.(-2 * t) + (2 * sin.(t) - cos.(t)) / 5
# elseif gen.outputfunc == zero 
#     xanalytic = x0[1] * exp.(-2 * t)
# end

# # Compute the error.
# err_analytic_jusdl = xanalytic - xjusdl
# err_analytic_diffeq = xanalytic - xdiffeq
# err_jusdl_diffeq = xjusdl - xdiffeq

# # # Plot the results.
# p1 = plot(t, xjusdl, label=:xjusdl)
#     plot!(t, xdiffeq, label=:xdiffeq)
#     plot!(t, xanalytic, label=:analytic)
# p2 = plot(t, abs.(err_analytic_jusdl), label=:err_analytic_jusdl)
#     plot!(t, abs.(err_analytic_diffeq), label=:err_analytic_diffeq)
# p3 = plot(t, abs.(err_analytic_diffeq), label=:err_analytic_diffeq)
# p4 = plot(t, abs.(err_jusdl_diffeq), label=:err_jusdl_diffeq)
# display(plot(p1, p2, p3, p4))