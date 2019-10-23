using Jusdl 
using Plots
using LinearAlgebra

t0, dt, tf = 0., 0.01, 10.

ds1 = LorenzSystem(Bus(3), Bus(3))
ds2 = LorenzSystem(Bus(3), Bus(3))
# coupler = Coupler([-1. 1.; 1. -1], diagm([1., 0., 0]))
# mem1 = Memory(Bus(3), 1)
# mem2 = Memory(Bus(3), 1)

# connect(ds1.output, coupler.input[1:3])
# connect(ds2.output, coupler.input[4:6])
# connect(coupler.output[1:3], mem1.input)
# connect(coupler.output[4:6], mem2.input)
# connect(mem1.output, ds1.input)
# connect(mem2.output, ds2.input)

# sub = SubSystem([ds1, ds2, coupler, mem1, mem2], nothing, nothing)
sub = Network([ds1, ds2], [-1. 1.; 1. -1], diagm([1., 0., 0.]), nothing, nothing)
model = Model(sub)
# model = Model(ds1, ds2, coupler, mem1, mem2)


# gen = FunctionGenerator(sin)
# adder = Adder(Bus(2), (+, -))
# mem = Memory(Bus(1), 1)

# connect(gen.output, adder.input[1])
# connect(adder.output, mem.input)
# connect(mem.output, adder.input[2])

# model = Model(gen, adder, mem)

# initialize(model)
# set!(model.clk, t0, dt, tf)
# run(model)
# release(model)
# terminate(model)

sim = simulate(model, t0, dt, tf)

display(model.taskmanager.pairs[sub])
