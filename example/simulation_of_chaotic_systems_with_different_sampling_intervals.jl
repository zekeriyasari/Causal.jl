# This file illustrates the simulation of chaotic systems with different sampling intervals.

using Jusdl 
using Plots
using LinearAlgebra

# Simulation settings 
t0, tf = 0., 50.

dts = [0.005, 0.010]
writers = []
for dt in dts
    # Construct model blocks
    ds = LorenzSystem(nothing, Bus(3), state=[10., 10., 10.])
    # ds = LinearSystem(nothing, Bus(3), A=diagm(-ones(3)), C=diagm(ones(3)), state=[10., 10., 10.])
    writer = Writer(Bus(length(ds.output)))

    # Connect model blocks
    connect(ds.output, writer.input)

    # Construct model 
    model = Model(ds, writer)

    # Simulate model 
    sim = simulate(model, t0, dt, tf)

    # Save the solution 
    push!(writers, writer)
end

 # Read simulation data
t1, x1 = read(writers[1], flatten=true)
t2, x2 = read(writers[2], flatten=true)
p1 = plot(t1, x1[:, 1], label="dt="*string(dts[1]), size=(1000, 400))
    plot!(t2, x2[:, 1], label="dt="*string(dts[2]))
p2 = plot(x1[:, 1], x1[:, 2], label="dt="*string(dts[1]),  size=(1000, 400))
    plot!(x2[:, 1], x2[:, 2], label="dt="*string(dts[2]))
display(plot(p1, p2))
