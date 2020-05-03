# # This file includes the Network type 

# import GraphPlot.gplot


# ##### Network
# @doc raw"""
#     Network(nodes, conmat, cplmat; inputnodeidx, outputnodeidx, clusters)

# Constructs a `Network` consisting of `nodes` with the connection matrix `conmat` and the coupling matrix `cplmat`. The dynamics of the `Network` evolves by,
# ```math 
#     \dot{x}_i = f(x_i) + \sum_{j = 1}^n \epsilon_{ij} P x_j \quad i = 1, \ldots, n
# ```
# where ``n`` is the number of nodes, ``f`` is the function corresponding to individual node dynamics, ``\epsilon_{ij}`` is the coupling strength between nodes ``i`` and ``j``. The diagonal matrix ``P`` determines the state variables through which the nodes are coupled. In the equation above, we have `conmat` is eqaul to ``E = [\epsilon_{ij}]`` and `cplmat` is eqaul to ``P``.

# `inputnodeidx` and `outputnodeidx` is the input and output node indices for the input and output, respectively. `clusters` is the set of indices of node groups in the same cluster. `inputnodeidx` and `outputnodeidx` may be of type `Nothing`, `AbstractPort` or `Vector{<:Link}`.
# """
# mutable struct Network{IB, OB, TR, HS, CB, CMP, CNM, CPM} <: AbstractSubSystem
#     @generic_system_fields
#     components::CMP
#     conmat::CNM 
#     cplmat::CPM
#     clusters::Vector{UnitRange{Int}}
#     function Network(nodes, conmat, cplmat=coupling(length(nodes[1].output)); inputnodeidx=[], 
#         outputnodeidx=1:length(nodes), clusters=[1:length(nodes)], callbacks=nothing, name=Symbol())

#         # Construct network components
#         coupler = construct_coupler(conmat, cplmat)
#         memories = construct_memories(nodes)
#         adders = construct_adders(nodes[inputnodeidx])
#         components = [nodes..., coupler, memories..., adders...]

#         # Construct input and output
#         inputport = construct_inputbus(adders)
#         outputport = construct_outputbus(nodes[outputnodeidx])
        
#         # Construct network
#         trigger = Inpin()
#         handshake = Outpin{Bool}()
#         net = new{typeof(inputport), typeof(outputport), typeof(trigger), typeof(handshake), typeof(callbacks), 
#             typeof(components), typeof(conmat), typeof(cplmat)}(inputport, outputport, trigger, handshake, callbacks, 
#             name, uuid4(), components, conmat, cplmat, clusters)
        
#             # Connect network internally.
#         connect_internally(net, inputnodeidx)
#     end
# end


# show(io::IO, net::Network) = print(io, "Network(conmat:$(net.conmat), cplmat:$(net.cplmat)",
#     "input:$(net.input), output:$(net.output))")


# ##### Network auxilary components construction
# construct_coupler(conmat, cplmat) = Coupler(conmat, cplmat)
# construct_memories(nodes) = [Memory(Inport(length(node.output)), 1, initial=node.state) for node in nodes]
# construct_adders(inputnodes) = [construct_an_adder(length(node.input), 2, fill(+, 2)) for node in inputnodes]
# function construct_an_adder(dim, n, ops)
#     K = hcat([op(diagm(ones(dim))) for op in ops]...)
#     StaticSystem((u, t) -> K * u, Inport(n * dim), Outport(dim))
# end


# ##### Network input-output bus construction
# function construct_inputbus(adders=[])
#     if isempty(adders)
#         inputport = nothing
#     else
#         inpins = vcat([adder.input[Int(end / 2) + 1 : end] for adder in adders]...)
#         inputport = Inport(inpins)
#     end
#     return inputport
# end

# function construct_outputbus(outputnodes)
#     if isempty(outputnodes)
#         outputport = nothing
#     else
#         outpins = vcat([node.output.pins for node in outputnodes]...)
#         outputport = Outport(outpins)
#     end
#     return outputport
# end


# ##### Network internal connection.
# function connect_internally(net::Network, inputnodeidx)
#     nodes = filter(comp -> typeof(comp) <: AbstractDynamicSystem, net.components)
#     coupler = filter(comp -> typeof(comp) <: Coupler, net.components)[1]
#     memories = filter(comp -> typeof(comp) <: Memory, net.components)
#     adders = filter(comp -> typeof(comp) <: StaticSystem, net.components)
#     inputnodes, noninputnodes = dividecomponents(nodes, inputnodeidx)
#     inputmemories, noninputmemories = dividecomponents(memories, inputnodeidx)
#     connect_nodes_to_coupler(nodes, coupler)
#     connect_coupler_to_memories(coupler, memories)
#     connect_memories_to_nodes(noninputmemories, noninputnodes)
#     connect_memories_to_adders(inputmemories, adders)
#     connect_adders_to_nodes(adders, inputnodes)
#     net
# end

# function connect_nodes_to_coupler(nodes, coupler)
#     numnodes = size(coupler.conmat, 1)
#     dimnodes = size(coupler.cplmat, 1)
#     for (node, idx) in zip(nodes, 1 : dimnodes : numnodes * dimnodes) 
#         connect(node.output, coupler.input[idx : idx + dimnodes - 1])
#     end
# end

# function connect_coupler_to_memories(coupler, memories)
#     numnodes = size(coupler.conmat, 1)
#     dimnodes = size(coupler.cplmat, 1)
#     for (memory, idx) in zip(memories, 1 : dimnodes : numnodes * dimnodes) 
#         connect(coupler.output[idx : idx + dimnodes - 1], memory.input)
#     end
# end

# function connect_memories_to_nodes(memories, nodes)
#     for (memory, node) in zip(memories, nodes)
#         connect(memory.output, node.input)
#     end  
# end

# function connect_memories_to_adders(memories, adders)
#     for (memory, adder) in zip(memories, adders)
#         connect(memory.output, adder.input[1 : length(memory.output)])
#     end
# end

# function connect_adders_to_nodes(adders, nodes)
#     for (adder, node) in zip(adders, nodes)
#         connect(adder.output, node.input)
#     end
# end

# function dividecomponents(nodes, inputnodeidx)
#     allidx = collect(1:length(nodes))
#     inputmask = in(inputnodeidx).(allidx)
#     noninputmask = .!(inputmask)
#     nodes[inputmask], nodes[noninputmask]
# end

# """
#     nodes(net::Network)

# Returns the `nodes` of `net`. `nodes` are the dynamical system components of `net`.
# """
# nodes(net::Network) = filter(comp -> typeof(comp) <: AbstractDynamicSystem, net.components)

# """
#     numnodes(net::Network)

# Returns the number of nodes in `net`.
# """
# numnodes(net::Network) = size(net.conmat, 1)

# """
#     dimnodes(net::Network)

# Returns the dimension of nodes in `net`.
# """
# dimnodes(net::Network) = size(net.cplmat, 1)

# # #
# # # Opens the input by of `net` corresponding to node whose index is `idx`.
# # #
# # function openinputbus(net::Network, idx::Int)
# #     netnodes = nodes(net)
# #     nodes = netnodes[idx]
# #     inputport = node.input
# #     dimnode = length(inputport)
# #     masterlinks = getmaster(inputport)
# #     adder = construct_an_adder(dimnode, 2, (+, -))
# #     disconnect(masterlinks, inputport)
# #     connect(masterlinks, adder.input[1:dimnode])
# #     connect(adder.output, inputport)
# #     push!(net.components, adder)
# #     # TODO: Complete function 
# # end

# ##### Plotting networks
# """
#     gplplot(net::Network, args...; kwargs...)

# Plots `net`.
# """
# gplot(net::Network, args...; kwargs...) = 
#     gplot(SimpleGraph(net.conmat), nodelabel=1:size(net.conmat, 1), args...; kwargs...)

# ##### Construction of coupling matrix
# """
#     coupling(d, idx::Vector{Int})

# Returns a `d`-by-`d` diagonal matrix whose diagonal elements are ones corresponding to `idx`.

#     coupling(d, idx::Int)

# Returns a `d`-by-`d` diagonal matrix whose diagonal element is one corresponding to `idx`.

# # Example 
# ```jldoctest
# julia> coupling(3, [1, 2])
# 3×3 Array{Float64,2}:
#  1.0  0.0  0.0
#  0.0  1.0  0.0
#  0.0  0.0  0.0

# julia> coupling(3, 1)
# 3×3 Array{Float64,2}:
#  1.0  0.0  0.0
#  0.0  0.0  0.0
#  0.0  0.0  0.0
# ```
# """
# coupling(d, idx::Vector{Int}) = (v = zeros(d); v[idx] .= 1; diagm(v))
# coupling(n, idx::Int) = coupling(n, [idx])

# ##### Construction of connection matrices of different network toplogies.

# """
#     topology(name::Symbol, args...; weight::Real=1., timevarying::Bool=false)


# Returns an outer connectivity matrix whose graph is given by `name`. `weight` is the scaling vector of the connection matrix. If `timevarying` is `true`, all elements of the connectivity matrix is a function of time `t`.

# !!! note 
#     See (https://juliagraphs.github.io/LightGraphs.jl/latest/generators/#Graph-Generators-1) for different `name`s.

# # Example
# ```jldoctest
# julia> topology(:path_graph, 5, weight=10)
# 5×5 Array{Int64,2}:
#  -10   10    0    0    0
#   10  -20   10    0    0
#    0   10  -20   10    0
#    0    0   10  -20   10
#    0    0    0   10  -10
# ```
# """
# function topology(name::Symbol, args...; weight::Real=1., timevarying::Bool=false, kwargs...)
#     conmat = weight * (-1) * collect(laplacian_matrix(eval(name)(args...; kwargs...)))
#     timevarying ? maketimevarying(conmat) : conmat 
# end

# @deprecate uniformconnectivty(args...; kwargs...) topology(args...; kwargs...)

# """
#     cgsconnectivity(graph::AbstractGraph; weight::Real=1., timevarying::Bool=false)

# Constructs an outer connnectivity matrix corresponding to *connection graph stability* method. `graph` is graph of the network, `weight` scales the connectivity matrix. If `timevarying` is `true`, each element of the connnectivity matrix is a function of time `t`.

#     cgsconnectivity(adjmat::AbstractMatrix; weight::Real=1.,  timevarying::Bool=false)

# Constructs an outer connnectivity matrix corresponding to *connection graph stability* method. `adjmat` is the adjacency matrix of the network, `weight` scales the connectivity matrix. If `timevarying` is `true`, each element of the connnectivity matrix is a function of time `t`.

#     cgsconnectivity(topology::Symbol, args...; weight::Real=1., timevarying::Bool=false, kwargs...)

# Constructs an outer connnectivity matrix corresponding to *connection graph stability* method. `topology` is the name of the graph of the network, `weight` scales the connectivity matrix. If `timevarying` is `true`, each element of the connnectivity matrix is a function of time `t`.

# # Example
# ```jldoctest
# julia> cgsconnectivity(:path_graph, 5)
# 5×5 Array{Float64,2}:
#  -0.8   0.8   0.0   0.0   0.0
#   0.8  -2.0   1.2   0.0   0.0
#   0.0   1.2  -2.4   1.2   0.0
#   0.0   0.0   1.2  -2.0   0.8
#   0.0   0.0   0.0   0.8  -0.8
# ```

# # References 
# * Belykh, V. N., Belykh, I. V., & Hasler, M. (2004). Connection graph stability method for synchronized coupled chaotic systems. Physica D: nonlinear phenomena, 195(1-2), 159-187.
# """
# function cgsconnectivity(graph::AbstractGraph; weight::Real=1., timevarying::Bool=false)
#     graphedges = edges(graph)
#     graphvertices = vertices(graph)
#     numvertices = nv(graph)
#     edgepathlength = Dict(zip(graphedges, zeros(length(graphedges))))
#     # Find shortest path lengths for each of edges.
#     for edge in graphedges
#         red = Edge(dst(edge), src(edge))
#         for i in 1 : numvertices
#             for j in i + 1 : numvertices
#                 path_ij = a_star(graph, i, j) 
#                 if edge in path_ij || red in path_ij
#                     edgepathlength[edge] += 1
#                 end
#             end
#         end
#     end
#     # Construct connection matrix
#     conmat = zeros(numvertices, numvertices)
#     for (edge, pathlength) in edgepathlength
#         conmat[src(edge), dst(edge)] = pathlength
#         conmat[dst(edge), src(edge)] = pathlength
#     end
#     foreach(i -> (conmat[i, i] = -sum(conmat[i, :])), 1 : numvertices)
#     conmat *= weight / numvertices
#     timevarying ? maketimevarying(conmat) : conmat
# end
# cgsconnectivity(adjmat::AbstractMatrix; weight::Real=1.,  timevarying::Bool=false) = 
#     cgsconnectivity(SimpleGraph(adjmat), weight=weight, timevarying=timevarying)
# cgsconnectivity(topology::Symbol, args...; weight::Real=1., timevarying::Bool=false, kwargs...) = 
#     cgsconnectivity(eval(topology)(args...; kwargs...), weight=weight, timevarying=timevarying)

# """
#     clusterconnectivity(clusters::AbstractRange...; weight=1., timevarying::Bool=false)

# Construct an outer connnectivity matrix using *arbitrary clusters* method. `clusters` is the set of node indices in each clusters. `weight` scales the connectivity matrix. If  `timevarying` is `true`, all elements of the connectivity matrix is a function of time `t`.

# # Example 
# ```jldoctest
# julia> clusterconnectivity(1:2, 3:6)
# 6×6 Array{Float64,2}:
#  -3.0   3.0  -1.0   1.0   0.0   0.0
#   3.0  -3.0   1.0  -1.0   0.0   0.0
#  -1.0   1.0  -9.0   3.0   3.0   3.0
#   1.0  -1.0   3.0  -9.0   3.0   3.0
#   0.0   0.0   3.0   3.0  -9.0   3.0
#   0.0   0.0   3.0   3.0   3.0  -9.0
# ```

# # References
# * Ma, Z., Liu, Z., & Zhang, G. (2006). A new method to realize cluster synchronization in connected chaotic networks. Chaos: An Interdisciplinary Journal of Nonlinear Science, 16(2), 023103.

# """
# function clusterconnectivity(clusters::AbstractRange...; weight=1., timevarying::Bool=false)
#     numnodes = clusters[end][end]
#     lenclusters = length.(clusters)
#     numclusters = length(clusters)
#     conmat = zeros(numnodes, numnodes)
#     for i = 1 : numclusters - 1
#         cluster = clusters[i]
#         lencluster = lenclusters[i]
#         nextcluster = clusters[i + 1]
#         lennectcluster = lenclusters[i + 1]
#         val = diagonal(lencluster)
#         conmat[cluster, cluster] = val
#         if lenclusters == lennectcluster
#             conmat[cluster, nextcluster] = val
#             conmat[nextcluster, cluster] = val
#         else
#             conmat[cluster, nextcluster] = hcat(val, zeros(lencluster, lennectcluster - lencluster))
#             conmat[nextcluster, cluster] = vcat(val, zeros(lennectcluster - lencluster, lencluster))
#         end
#     end
#     cluster = clusters[end]
#     lencluster = lenclusters[end]
#     conmat[cluster, cluster] = diagonal(lencluster)

#     conmat[clusters[1], clusters[1]] .*= 3.
#     for cluster in clusters[2 : end - 1]
#         conmat[cluster, cluster] .*= 5.
#     end
#     conmat[clusters[end], clusters[end]] .*= 3.
#     conmat *= weight
#     timevarying ? maketimevarying(conmat) : conmat
# end

# diagonal(n::Int) = (a = ones(n, n); d = -(n - 1); foreach(i -> (a[i, i] = d), 1 : n); a) 

# """
#     maketimevarying(mat::AbstractMatrix{<:Real})

# Returns a matrix of function of time `t` corresponding to `mat`.

# # Example
# ```jldoctest
# julia> a = collect(reshape(1:9, 3, 3))
# 3×3 Array{Int64,2}:
#  1  4  7
#  2  5  8
#  3  6  9

# julia> b = maketimevarying(a);

# julia> b[1, 1](0.)
# 1

# julia> b[3, 2](0.)
# 6
# ```
# """
# maketimevarying(mat::AbstractMatrix{<:Real}) = convert(Matrix{Function}, map(item -> t -> item, mat))

# ##### Changing network topology
# """
#     changeweight(net::Network, src::Int, dst::Int, weight)

# Changes the weight of the coupling between the nodes `src` and `dst` with `weight`.
# """
# function changeweight(net::Network, src::Int, dst::Int, weight)
#     if length(net.clusters) == 1
#         if eltype(net.conmat) <: Real
#             oldweight = net.conmat[src, dst]
#             net.conmat[src, dst] = weight
#             net.conmat[dst, src] = weight
#             net.conmat[src, src] -= weight - oldweight
#             net.conmat[dst, dst] -= weight - oldweight
#         else
#             @warn "Change for time varying network. To be implemented. Returning..."
#         end
#     else
#         @warn "Change for time clusters. To be implemented. Returning..."
#         return  
#     end
# end

# """
#     deletelink(net::Network, src::Int, dst::Int)

# Changes the strength of the link between `src` and `dst` to zero.
# """
# function deletelink(net::Network, src::Int, dst::Int)
#     if length(net.clusters) == 1
#         if eltype(net.conmat) <: Real
#             net.conmat[src, src] += net.conmat[src, dst]
#             net.conmat[dst, dst] += net.conmat[src, dst]
#             net.conmat[src, dst] = 0
#             net.conmat[dst, src] = 0
#         else
#             @warn "Delete from time varying network. To be implemented. Returning..."
#         end
#     else
#         @warn "Delete from clusters. To be implemented. Returning..."
#         return  
#     end
# end

# ##### Pin network 
# function pin(ds::AbstractDynamicSystem, net::Network, idx=collect(1 : nodes(net)), weights=ones(length(idx)))
#     # TODO: Complete the function.
# end