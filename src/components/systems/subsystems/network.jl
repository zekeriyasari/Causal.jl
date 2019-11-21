# This file includes the Network type 

import GraphPlot.gplot


##### Network
mutable struct Network{IB, OB, T, H, CMP, CNM, CPM} <: AbstractSubSystem
    @generic_system_fields
    components::CMP
    conmat::CNM 
    cplmat::CPM
    clusters::Vector{UnitRange{Int}}
    function Network(nodes::AbstractArray, conmat::AbstractMatrix, 
        cplmat::AbstractMatrix=coupling(length(nodes[1].output)); inputnodeidx=[], 
        outputnodeidx=1:length(nodes), clusters=[1:length(nodes)])
        coupler = construct_coupler(conmat, cplmat)
        memories = construct_memories(nodes)
        adders = construct_adders(nodes[inputnodeidx])
        components = [nodes..., coupler, memories..., adders...]
        trigger = Link()
        handshake = Link{Bool}()
        inputbus = construct_inputbus(adders)
        outputbus = construct_outputbus(nodes[outputnodeidx])
        net = new{typeof(inputbus), typeof(outputbus), typeof(trigger), typeof(handshake), typeof(components), 
            typeof(conmat), typeof(cplmat)}(inputbus, outputbus, trigger, handshake, Callback[], uuid4(), components,
            conmat, cplmat, clusters)
        connect_internally(net, inputnodeidx)
    end
end


show(io::IO, net::Network) = print(io, "Network(conmat:$(checkandshow(net.conmat)), cplmat:$(checkandshow(net.cplmat))",
    "input:$(checkandshow(net.input)), output:$(checkandshow(net.output)))")


##### Network auxilary components construction
construct_coupler(conmat, cplmat) = Coupler(conmat, cplmat)
construct_memories(nodes) = [Memory(Bus(length(node.output)), 1, initial=node.state) for node in nodes]
construct_adders(inputnodes) = [construct_an_adder(length(node.input), 2, fill(+, 2)) for node in inputnodes]
function construct_an_adder(dim, n, ops)
    K = hcat([op(diagm(ones(dim))) for op in ops]...)
    StaticSystem(Bus(n * dim), Bus(dim), (u, t) -> K * u)
end


##### Network input-output bus construction
function construct_inputbus(adders=[])
    if isempty(adders)
        inputbus = nothing
    else
        links = vcat([adder.input[Int(end / 2) + 1 : end] for adder in adders]...)
        inputbus = Bus(length(links))
        for (i, link) in enumerate(links)
            inputbus[i] = link
        end
    end
    return inputbus
end

function construct_outputbus(outputnodes)
    if isempty(outputnodes)
        outputbus = nothing
    else
        links = vcat([node.output.links for node in outputnodes]...)
        outputbus = Bus(length(links))
        for (i, link) in enumerate(links)
            outputbus[i] = link
        end
    end
    return outputbus
end


##### Network internal connection.
function connect_internally(net::Network, inputnodeidx)
    nodes = filter(comp -> typeof(comp) <: AbstractDynamicSystem, net.components)
    coupler = filter(comp -> typeof(comp) <: Coupler, net.components)[1]
    memories = filter(comp -> typeof(comp) <: Memory, net.components)
    adders = filter(comp -> typeof(comp) <: StaticSystem, net.components)
    inputnodes, noninputnodes = dividecomponents(nodes, inputnodeidx)
    inputmemories, noninputmemories = dividecomponents(memories, inputnodeidx)
    connect_nodes_to_coupler(nodes, coupler)
    connect_coupler_to_memories(coupler, memories)
    connect_memories_to_nodes(noninputmemories, noninputnodes)
    connect_memories_to_adders(inputmemories, adders)
    connect_adders_to_nodes(adders, inputnodes)
    net
end

function connect_nodes_to_coupler(nodes, coupler)
    numnodes = size(coupler.conmat, 1)
    dimnodes = size(coupler.cplmat, 1)
    for (node, idx) in zip(nodes, 1 : dimnodes : numnodes * dimnodes) 
        connect(node.output, coupler.input[idx : idx + dimnodes - 1])
    end
end

function connect_coupler_to_memories(coupler, memories)
    numnodes = size(coupler.conmat, 1)
    dimnodes = size(coupler.cplmat, 1)
    for (memory, idx) in zip(memories, 1 : dimnodes : numnodes * dimnodes) 
        connect(coupler.output[idx : idx + dimnodes - 1], memory.input)
    end
end

function connect_memories_to_nodes(memories, nodes)
    for (memory, node) in zip(memories, nodes)
        connect(memory.output, node.input)
    end  
end

function connect_memories_to_adders(memories, adders)
    for (memory, adder) in zip(memories, adders)
        connect(memory.output, adder.input[1 : length(memory.output)])
    end
end

function connect_adders_to_nodes(adders, nodes)
    for (adder, node) in zip(adders, nodes)
        connect(adder.output, node.input)
    end
end

function dividecomponents(nodes, inputnodeidx)
    allidx = collect(1:length(nodes))
    inputmask = in(inputnodeidx).(allidx)
    noninputmask = .!(inputmask)
    nodes[inputmask], nodes[noninputmask]
end


nodes(net::Network) = filter(comp -> typeof(comp) <: AbstractDynamicSystem, net.components)
numnodes(net::Network) = size(net.conmat, 1)
dimnodes(net::Network) = size(net.cplmat, 1)

##### Plotting networks    
gplot(net::Network) = gplot(SimpleGraph(net.conmat), nodelabel=1:size(net.conmat, 1))

##### Construction of coupling matrix
coupling(d, idx::Vector{Int}) = (v = zeros(d); v[idx] .= 1; diagm(v))
coupling(n, idx::Int) = coupling(n, [idx])

##### Construction of connection matrices of different network toplogies.

function uniformconnectivity(topology::Symbol, args...; weight::Real=1., timevarying::Bool=false, kwargs...)
    conmat = weight * (-1) * collect(laplacian_matrix(eval(topology)(args...; kwargs...)))
    timevarying ? maketimevarying(conmat) : conmat 
end

function cgsconnectivity(graph::AbstractGraph; weight::Real=1., timevarying::Bool=false)
    graphedges = edges(graph)
    graphvertices = vertices(graph)
    numvertices = nv(graph)
    edgepathlength = Dict(zip(graphedges, zeros(length(graphedges))))
    # Find shortest path lengths for each of edges.
    for edge in graphedges
        red = Edge(dst(edge), src(edge))
        for i in 1 : numvertices
            for j in i + 1 : numvertices
                path_ij = a_star(graph, i, j) 
                if edge in path_ij || red in path_ij
                    edgepathlength[edge] += 1
                end
            end
        end
    end
    # Construct connection matrix
    conmat = zeros(numvertices, numvertices)
    for (edge, pathlength) in edgepathlength
        conmat[src(edge), dst(edge)] = pathlength
        conmat[dst(edge), src(edge)] = pathlength
    end
    foreach(i -> (conmat[i, i] = -sum(conmat[i, :])), 1 : numvertices)
    conmat *= weight / numvertices
    timevarying ? maketimevarying(conmat) : conmat
end
cgsconnectivity(adjmat::AbstractMatrix; weight::Real=1.,  timevarying::Bool=false) = 
    cgsconnectivity(SimpleGraph(adjmat), weight=weight, timevarying=timevarying)
cgsconnectivity(topology::Symbol, args...; weight::Real=1., timevarying::Bool=false, kwargs...) = 
    cgsconnectivity(eval(topology)(args...; kwargs...), weight=weight, timevarying=timevarying)

function clusterconnectivity(clusters::AbstractRange...; weight=1., timevarying::Bool=false)
    numnodes = clusters[end][end]
    lenclusters = length.(clusters)
    numclusters = length(clusters)
    conmat = zeros(numnodes, numnodes)
    for i = 1 : numclusters - 1
        cluster = clusters[i]
        lencluster = lenclusters[i]
        nextcluster = clusters[i + 1]
        lennectcluster = lenclusters[i + 1]
        val = diagonal(lencluster)
        conmat[cluster, cluster] = val
        if lenclusters == lennectcluster
            conmat[cluster, nextcluster] = val
            conmat[nextcluster, cluster] = val
        else
            conmat[cluster, nextcluster] = hcat(val, zeros(lencluster, lennectcluster - lencluster))
            conmat[nextcluster, cluster] = vcat(val, zeros(lennectcluster - lencluster, lencluster))
        end
    end
    cluster = clusters[end]
    lencluster = lenclusters[end]
    conmat[cluster, cluster] = diagonal(lencluster)

    conmat[clusters[1], clusters[1]] .*= 3.
    for cluster in clusters[2 : end - 1]
        conmat[cluster, cluster] .*= 5.
    end
    conmat[clusters[end], clusters[end]] .*= 3.
    conmat *= weight
    timevarying ? maketimevarying(conmat) : conmat
end

diagonal(n::Int) = (a = ones(n, n); d = -(n - 1); foreach(i -> (a[i, i] = d), 1 : n); a) 

maketimevarying(mat::AbstractMatrix{<:Real}) = convert(Matrix{Function}, map(item -> t -> item, mat))

##### Changing network topology
function changeweight(net::Network, src::Int, dst::Int, weight)
    if length(net.clusters) == 1
        if eltype(net.conmat) <: Real
            oldweight = net.conmat[src, dst]
            net.conmat[src, dst] = weight
            net.conmat[dst, src] = weight
            net.conmat[src, src] -= weight - oldweight
            net.conmat[dst, dst] -= weight - oldweight
        else
            @warn "Change for time varying network. To be implemented. Returning..."
        end
    else
        @warn "Change for time clusters. To be implemented. Returning..."
        return  
    end
end

function deletelink(net::Network, src::Int, dst::Int)
    if length(net.clusters) == 1
        if eltype(net.conmat) <: Real
            net.conmat[src, src] += net.conmat[src, dst]
            net.conmat[dst, dst] += net.conmat[src, dst]
            net.conmat[src, dst] = 0
            net.conmat[dst, src] = 0
        else
            @warn "Delete from time varying network. To be implemented. Returning..."
        end
    else
        @warn "Delete from clusters. To be implemented. Returning..."
        return  
    end
end

##### Pin network 
function pin(ds::AbstractDynamicSystem, net::Network, idx=collect(1 : nodes(net)), weights=ones(length(idx)))
    # TODO: Complete the function.
end