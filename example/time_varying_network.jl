using Jusdl 
using Plots 

# Define the network parameters 
numnodes = 2
nodes = [LorenzSystem(10, 8/3, 28, 1, (x,u,t) -> x, rand(3), 0., Bus(3), Bus(3)) for i = 1 : numnodes]
weightpos(t, high=5., low=0., per=100.) = (0 <= mod(t, per) <= per / 2) ? high : low
weightneg(t, high=-5., low=0., per=100.) = (0 <= mod(t, per) <= per / 2) ? high : low
adjmat = [weightneg weightpos; weightpos weightneg]
cplmat = [1 0 0; 0 0 0; 0 0 0]
net = Network(nodes, adjmat, cplmat)
writer = Writer(Bus(length(net.output)))

# Connect the blocks
connect(net.output, writer.input)

# Construct the model 
model = Model(net, writer)

# Simulate the model 
sim = simulate(model, 0, 0.01, 500)

# Read and process the simulation data.
content = read(writer)
t = vcat(collect(keys(content))...)
x = collect(hcat(vcat(collect(values(content))...)...)')
plot(t, x[:, 1])
plot!(t, x[:, 4])
plot(t, abs.(x[:, 1] - x[:, 4]))
plot!(t, map(weightpos, t))

