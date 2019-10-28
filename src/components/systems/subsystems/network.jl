# This file includes the Network type 

import GraphPlot.gplot

alloutputlinks(components) = vcat([component.output.links for component in components]...)


mutable struct Network{IB, OB, T, H, CMP, CNM, CPM} <: AbstractSubSystem
    @generic_system_fields
    components::CMP
    conmat::CNM 
    cplmat::CPM
    clusters::Vector{UnitRange{Int}}
    function Network(components::AbstractArray, conmat::AbstractMatrix, 
        cplmat::AbstractMatrix=getcplmat(length(components[1].output)), input=nothing, 
        output=alloutputlinks(components); clusters=[1:length(components)])
        # Construct input output
        trigger = Link()
        handshake = Link{Bool}()
         if typeof(input) <: AbstractVector{<:Link}
            inputbus = Bus(length(input))
            for (i, link) in enumerate(input)
                inputbus[i] = link
            end
            # inputbus .= input
        else 
            inputbus = input
        end
        
        if typeof(output) <: AbstractVector{<:Link}
            outputbus = Bus(length(output))
            for (i, link) in enumerate(output)
                outputbus[i] = link
            end
            # outputbus .= output
        else
            outputbus = output
        end

        ##### Connect components
        numnodes = size(conmat, 1)
        dimnodes = size(cplmat, 1)
        coupler = Coupler(conmat, cplmat)
        memories = [Memory(Bus(dimnodes), 1, initial=zeros(dimnodes)) for i = 1 : numnodes]
        for (component, idx) in zip(components, 1 : dimnodes : numnodes * dimnodes)     # Connect components to coupler
            connect(component.output, coupler.input[idx : idx + dimnodes - 1])
        end
        for (memory, idx) in zip(memories, 1 : dimnodes : numnodes * dimnodes)          # Connect coupler to memories
            connect(coupler.output[idx : idx + dimnodes - 1], memory.input)
        end
        for (memory, component) in zip(memories, components)                            # Connect memories to components
            connect(memory.output, component.input)
        end
        allcomponents = [components..., coupler, memories...]
        new{typeof(inputbus), typeof(outputbus), typeof(trigger), typeof(handshake), typeof(allcomponents), 
            typeof(conmat), typeof(cplmat)}(inputbus, outputbus, trigger, handshake, Callback[], uuid4(), allcomponents,
            conmat, cplmat, clusters)
    end
end


show(io::IO, net::Network) = print(io, "Network(conmat:$(checkandshow(net.conmat)), cplmat:$(checkandshow(net.cplmat))",
    "input:$(checkandshow(net.input)), output:$(checkandshow(net.output)))")

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

