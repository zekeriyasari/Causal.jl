# This file includes the Network type 

import GraphPlot.gplot

alloutputlinks(components) = vcat([component.output.links for component in components]...)


mutable struct Network{IB, OB, L, C, T, S} <: AbstractSubSystem
    @generic_system_fields
    components::C
    conmat::T 
    cplmat::S 
    function Network(components::AbstractArray, conmat::AbstractMatrix, 
        cplmat::AbstractMatrix=getcplmat(length(components[1].output)), input=nothing, 
        output=alloutputlinks(components))
        # Construct input output
        trigger = Link()
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
        new{typeof(inputbus), typeof(outputbus), typeof(trigger), typeof(allcomponents), typeof(conmat), 
            typeof(cplmat)}(inputbus, outputbus, trigger, Callback[], uuid4(), allcomponents, conmat, cplmat)
    end
end


show(io::IO, net::Network) = print(io, "Network(conmat:$(checkandshow(net.conmat)), cplmat:$(checkandshow(net.cplmat))",
    "input:$(checkandshow(net.input)), output:$(checkandshow(net.output)))")

##### Plotting networks    
gplot(net::Network) = gplot(SimpleGraph(net.conmat), nodelabel=1:size(net.conmat, 1))

##### Construction of coupling matrix
getcplmat(d, idx::Vector{Int}) = (v = zeros(d); v[idx] .= 1; diagm(v))
getcplmat(n, idx::Int) = getcplmat(n, [idx])

##### Construction of different network toplogies.
getconmat(topology::Symbol, args...; weight=1., kwargs...) = 
    weight * (-1) * collect(laplacian_matrix(eval(topology)(args...; kwargs...)))

_getdiagonal(n::Int) = (a = ones(n, n); d = -(n - 1); foreach(i -> (a[i, i] = d), 1 : n); a) 

function getconmat(clusters::AbstractRange...; weight=1.)
    numnodes = clusters[end][end]
    lenclusters = length.(clusters)
    numclusters = length(clusters)
    mat = zeros(numnodes, numnodes)
    for i = 1 : numclusters - 1
        cluster = clusters[i]
        lencluster = lenclusters[i]
        nextcluster = clusters[i + 1]
        lennectcluster = lenclusters[i + 1]
        val = _getdiagonal(lencluster)
        mat[cluster, cluster] = val
        if lenclusters == lennectcluster
            mat[cluster, nextcluster] = val
            mat[nextcluster, cluster] = val
        else
            mat[cluster, nextcluster] = hcat(val, zeros(lencluster, lennectcluster - lencluster))
            mat[nextcluster, cluster] = vcat(val, zeros(lennectcluster - lencluster, lencluster))
        end
    end
    cluster = clusters[end]
    lencluster = lenclusters[end]
    mat[cluster, cluster] = _getdiagonal(lencluster)

    mat[clusters[1], clusters[1]] .*= 3.
    for cluster in clusters[2 : end - 1]
        mat[cluster, cluster] .*= 5.
    end
    mat[clusters[end], clusters[end]] .*= 3.

    weight * mat
end
