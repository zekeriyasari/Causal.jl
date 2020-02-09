# Construction and Simulation of Networks 

In this tutorial, we will simulate a network. A network is actually a subsystem. That is, a network consists of components that are connected to each other. See [Network](@ref) and [Subsystem](@ref) for more information networks and subsystem.

### Construction of Networks 
In this example, we will simulate a small network consisting of rwo dynamical systems. The network in this example consists of identical dynamical systems whose dynamics is given by
```math 
    \dot{x}_i = f(x_i) + \sum_\limits_{j = 1}^{N} \epsilon_{ij} P x_j, \quad i = 1, \ldots, N
```
where ``N`` is the number of node,  ``f`` is the vector function corresponding to the individual node dynamics, ``\epsilon_{ij}`` is the coupling strength between the nodes ``i`` and ``j``. The diagonal matrix ``P`` determines the way the nodes are connected to each other. In this simulation, we construct a network consisting of two nodes with Lorenz dynamics. The matrix ``E = [\epsilon_{ij}]`` determines the coupling strength and topology of the network: ``\epsilon_{ij} = 0`` if there is no connection between nodes ``i`` and ``j``, otherwise ``\epsilon_{ij} = 0``.
```@example network_tutorial
using Jusdl  # hide 
numnodes = 2
nodes = [LorenzSystem(Bus(3), Bus(3)) for i = 1 : numnodes]
conmat = [-1 1; 1 -1] * 10
cplmat = [1 0 0; 0 0 0; 0 0 0]
net = Network(nodes, conmat, cplmat, inputnodeidx=[], outputnodeidx=1:numnodes)
```
Note that the states of all the nodes are taken as output nodes. To save the output values of the nodes, we construct a writer. 
```@example network_tutorial
writer = Writer(Bus(length(net.output)))
```
We connect the network to the writer and construct the model 
```@example network_tutorial
connect(net.output, writer.input)
model = Model(net, writer)
```
At this point, we are ready to simulate the system. 
```@example network_tutorial
t0 = 0
dt = 0.01
tf = 100.
sim = simulate(model, t0, dt, tf)
```
Then, we read the data from the writers and plot the data. 
```@example network_tutorial 
using Plots 
t, x = read(writer, flatten=true)
p1 = plot(t, x[:, 1])
    plot!(t, x[:, 4])
p2 = plot(t, abs.(x[:, 1] - x[:, 4]))
p3 = plot(p1, p2, layout=(2,1))
savefig(p3, "network_simulation_plot.svg"); nothing # hide
```
![](network_simulation_plot.svg)

Note the system are synchronized, i.e., the error between the outputs of the nodes goes to zero as time goes to zero. This synchronization phenomenon depends on the coupling strength between the nodes. The synchronization is not achieved when he coupling strength between the nodes are is large enough.
