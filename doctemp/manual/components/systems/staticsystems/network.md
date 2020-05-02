# Network

A `Network` is a system consisting of connected systems. That is, a `Network` is actually modeled as a `SubSystem`.

## Construction of Networks
To construct a `Network` we have to specify the components, the outer connectivity matrix and the inner coupling matrix. Inputs and outputs can be assigned to the `Network`. See the main constructor.
```@docs 
Network
```
Let us continue with examples. We first construct a couple of dynamical systems.
```@repl network_ex 
using Jusdl # hide 
nodes = [LorenzSystem(Inport(3), Outport(3)) for i = 1 : 5]
```
Then, we connect the outer coupling matrix 
```@repl network_ex 
conmat = topology(:star_graph, 5, weight=5.)
```
and we construct the inner coupling matrix
```@repl network_ex 
cplmat = coupling(3, 1)
```
Now we are ready to construct the `Network`.
```@repl network_ex
net = Network(nodes, conmat, cplmat)
```

## Connection Matrices 
The outer connection matrix determines the topology and the strength of the links between the nodes of the network. There exist some methods for easy construction of outer connection matrices.
```@docs 
topology
cgsconnectivity
clusterconnectivity
```

## Plotting of Network 
It is also possible to plot the networks. Use `gplot` function for this purpose. 
```@docs 
gplot
```

## Modifying Networks 
The `Network`s can be modified through its connections. For example, the weight of the connection between nodes of the network can be changed or a connection can be deleted.
```@docs 
changeweight
deletelink
```

## Full API 
```@docs 
nodes(net::Network)
numnodes(net::Network)
dimnodes(net::Network)
coupling
maketimevarying
```