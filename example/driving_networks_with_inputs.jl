# This file includes an example to illustarate driving networks with inputs.

using Jusdl 
using Plots 

# Simulatin settings 
t0, dt, tf = 0., 0.005, 100.

# Construct model blocks
numnodes = 2
dimnodes = 3 
nodes = [LorenzSystem(Bus(dimnodes), Bus(dimnodes)) for i = 1 : numnodes]
conmat = uniformconnectivity(:path_graph, numnodes)
cplmat = coupling(dimnodes, 1)
net = Network(nodes, conmat, cplmat, [1, 2], [1, 2])
gen = SinewaveGenerator(amplitude=10., frequency=0.1)
writerout = Writer(Bus(length(net.output)))
writerin = Writer(Bus(length(net.input)))

foreach(link -> connect(gen.output, link), net.input) 
connect(net.output, writerout.input)
connect(net.input, writerin.input)

model = Model(net, writerout, writerin, gen)

sim = simulate(model, t0, dt, tf)

t, y = read(writerout, flatten=true)
t, u = read(writerin, flatten=true)

p1 = plot(t, y[:, 1], label=:y1)
    plot!(t, u[:, 1], label=:u1)
display(p1)