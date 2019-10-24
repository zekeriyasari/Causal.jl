using DifferentialEquations
using Plots 
using Jusdl
using LinearAlgebra

# freq = 5e3
# T = 1 / freq
# r = 10e3
# c = 10e-9
# τ = r * c
# func(dx, x, u, t) = (dx[1] = -1 / τ * u)
# x0 = zeros(1)
# tspan = (0., T/2)
# sol = solve(ODEProblem(func, x0, tspan, 0.5), saveat=T/100)
# p1 = plot(sol)
# display(p1)


freq = 5e3
T = 1 / freq
r = 10e3
c = 10e-9
τ = r * c

t0, dt, tf = 0, T/1000, 5T

gen = SquarewaveGenerator(high=0.5, low=-0.5, period=T)
ds = LinearSystem(Bus(), Bus(), A=diagm([0.]), B=diagm([1/τ]), C=diagm([-1.]), state=zeros(1))
writerin = Writer(Bus())
writerout = Writer(Bus())

connect(gen.output, writerin.input)
connect(gen.output, ds.input)
connect(ds.output, writerout.input)

model = Model(gen, ds, writerin, writerout)

sim = simulate(model, t0, dt, tf)

t, u = read(writerin, flatten=true)
t, y = read(writerout, flatten=true)

p1 = plot(t, u)
    plot!(t, y)
display(p1)
