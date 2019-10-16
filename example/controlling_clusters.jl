using Jusdl
using Plots 

# Simulation settings 
t0 = 0
dt = 0.001
tf = 500.

# Construct the network 
numnodes = 4 
dimnodes = 3
weightcon = 5.
weightpos(t, high=weightcon, low=0., per=100.) = (0 <= mod(t, per) <= per / 2) ? high : low
weightneg(t, high=-weightcon, low=0., per=100.) = (0 <= mod(t, per) <= per / 2) ? high : low
conmat = [
    t -> 3 * weightneg(t)   t -> 3 * weightpos(t)   t -> -weightcon         t -> weightcon;
    t -> 3 * weightpos(t)   t -> 3 * weightneg(t)   t -> weightcon          t -> -weightcon;
    t -> -weightcon         t -> weightcon          t -> -3 * weightcon     t -> 3 * weightcon;
    t -> weightcon          t -> -weightcon         t -> 3 * weightcon      t -> -3 * weightcon]
cplmat = [1 0 0; 0 0 0; 0 0 0]
net = Network([LorenzSystem(Bus(dimnodes), Bus(dimnodes)) for i = 1 : numnodes], conmat, cplmat)
writer = Writer(Bus(length(net.output)))

# Connect the model components 
connect(net.output, writer.input)

# Construct the model 
model = Model(net, writer)

# Simulate the model 
sim = simulate(model, t0, dt ,tf)

# Read simulation data 
t, x = read(writer, flatten=true)

p1 = plot(t, x[:, 1])
p2 = plot(t, abs.(x[:, 1] - x[:, 4]))
    plot!(t, map(weightpos, t), label=:coupling)
p3 = plot(t, abs.(x[:, 4] - x[:, 7]))
    plot!(t, map(weightpos, t), label=:coupling)
p4 = plot(t, abs.(x[:, 7] - x[:, 10]))
    plot!(t, map(weightpos, t), label=:coupling)
display(plot(p1, p2, p3, p4, layout=(4, 1)))
