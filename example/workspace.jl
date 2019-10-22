using Jusdl 
using Plots 

gen = SinewaveGenerator()
gain = Gain(Bus())
writer = Writer(Bus())

connect(gen.output, gain.input)
connect(gain.output, writer.input)

model = Model(gen, gain, writer)

initialize(model)
set!(model.clk, 0., 0.01, 100.)
run(model)

disconnect(gen.output, gain.input)
disconnect(gain.output, writer.input)

# sim = simulate(model, 0., 0.01, 100.)

# t, x = read(writer, flatten=true)

# tgen = launch(gen, true)
# tgain = launch(gain, true)

# put!(gen.trigger, 1.)
# put!(gain.trigger, 1.)
# put!(gen.trigger, 2.)
# put!(gain.trigger, 2.)

# terminate(gen)
# terminate(gain)
