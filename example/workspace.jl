using Jusdl 
using Plots 

gen = SinewaveGenerator()
gain = Gain(Bus(), gain=2.)
writerin = Writer(Bus())
writerout = Writer(Bus())

connect(gen.output, gain.input)
connect(gain.input, writerin.input)
connect(gain.output, writerout.input)

model = Model(gen, gain, writerin, writerout)

sim = simulate(model, 0., 0.01, 10.)

t, xin = read(writerin, flatten=true)
t, xout = read(writerout, flatten=true)

plot(t, xin)
plot!(t, xout)
