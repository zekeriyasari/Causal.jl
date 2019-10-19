# This file illuustrates the simulation of coupled dynamical systems 
using Jusdl 
using Plots 
using LinearAlgebra


# Define the simulation settings 
t0, dt, tf = 0., 0.01, 50.
eps = 5.  # In order for the solutions not to blow, eps <= 10.

# # Simulate the system using Jusdl by constructing explicite blocks
# ds1 = LinearSystem(Bus(3), Bus(3), A=diagm(-ones(3)), B=diagm(ones(3)), C=diagm(ones(3)), D=diagm(zeros(3)))
# ds2 = LinearSystem(Bus(3), Bus(3), A=diagm(-ones(3)), B=diagm(ones(3)), C=diagm(ones(3)), D=diagm(zeros(3)))
ds1 = LorenzSystem(Bus(3), Bus(3))
ds2 = LorenzSystem(Bus(3), Bus(3))
coupler = Coupler([-eps eps; eps -eps], diagm([1., 0., 0.]))
mem1 = Memory(Bus(length(ds1.output)), 1, initial=ds1.state)
mem2 = Memory(Bus(length(ds2.output)), 1, initial=ds2.state)
writerds1out = Writer(Bus(length(ds1.output)))
writerds2out = Writer(Bus(length(ds2.output)))
writerds1in = Writer(Bus(length(ds1.input)))
writerds2in = Writer(Bus(length(ds2.input)))

connect(ds1.output, mem1.input)
connect(mem1.output, coupler.input[1:3])
connect(coupler.output[1:3], ds1.input)
connect(ds2.output, mem2.input)
connect(mem2.output, coupler.input[4:6])
connect(coupler.output[4:6], ds2.input)

# connect(ds1.output, coupler.input[1:3])
# connect(coupler.output[1:3], mem1.input)
# connect(mem1.output, ds1.input)
# connect(ds2.output, coupler.input[4:6])
# connect(coupler.output[4:6], mem2.input)
# connect(mem2.output, ds2.input)
connect(ds1.output, writerds1out.input)
connect(ds2.output, writerds2out.input)
connect(ds1.input, writerds1in.input)
connect(ds2.input, writerds2in.input)

model = Model(ds1, ds2, coupler, mem1, mem2, writerds1out, writerds2out, writerds1in, writerds2in)

sim = simulate(model, t0, dt, tf)

t, x1 = read(writerds1out, flatten=true)
t, x2 = read(writerds2out, flatten=true)
t, u1 = read(writerds1in, flatten=true)
t, u2 = read(writerds2in, flatten=true)

ni = 1
nf = length(t)
p1 = plot(t[ni:nf],  x1[ni:nf, 1], label=:x1)
    plot!(t[ni:nf], u1[ni:nf, 1],  label=:u1)
p2 = plot(t[ni:nf], x2[ni:nf, 1],  label=:x2)
    plot!(t[ni:nf], u2[ni:nf, 1],  label=:u2)
p3 = plot(x1[ni:nf, 1], x1[ni:nf, 2], label=:x1y1)
p4 = plot(x1[ni:nf, 1] - x2[ni:nf, 1], label=:err)
display(plot(p1, p2, p3, p4, layout=(2,2)))