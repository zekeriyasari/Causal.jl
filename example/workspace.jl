# Step-by-step solution of chaotic systems 

using Jusdl 
using Plots
using DifferentialEquations 
using LinearAlgebra

# Simulation settings 
dstype = :LinearSystem  # Choose :LinearSystem or :LorenzSystem
x0 = ones(3)
t0, dt, tf = 0., 0.001, 100.


if dstype == :LorenzSystem
    ds = LorenzSystem(nothing, Bus(3), state=x0)
    f = (dx, x, u, t, sigma=10, beta=8/3, rho=28,) -> begin 
        dx[1] = sigma * (x[2] - x[1])
        dx[2] = x[1] * (rho - x[3]) - x[2]
        dx[3] = x[1] * x[2] - beta * x[3]
    end
elseif dstype == :LinearSystem
    A=diagm(-1*ones(3))
    C=diagm(ones(3))
    ds = LinearSystem(nothing, Bus(3), A=A, C=C, state=x0)
    f = (dx, x, u, t, A=A) -> (dx .= A * x)
end
writer = Writer(Bus(3))
connect(ds.output, writer.input)
model = Model(ds, writer)
sim = simulate(model, t0, dt, tf)
t, xj = read(writer, flatten=true)

tspan = (t0, tf)
sol = solve(ODEProblem(f, x0, tspan), saveat=dt)
xd  = collect(hcat(sol.u[1 : size(xj, 1)]...)')


p1 = plot(t, xj[:, 1], label=:xj1)
    plot!(t, xd[:, 1], label=:xd1)
p2 = plot(t, abs.(xj[:, 1] - xd[:, 1]), label=:err1)
display(plot(p1, p2, layout=(2,1)))
