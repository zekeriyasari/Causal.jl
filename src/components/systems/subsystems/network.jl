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


getcplmat(d, idx::Vector{Int}) = (v = zeros(d); v[idx] .= 1; diagm(v))
getcplmat(n, idx::Int) = getcplmat(n, [idx])

getconmat(topology::Symbol, args...; weight=1., kwargs...) = 
    weight * (-1) * collect(laplacian_matrix(eval(topology)(args...; kwargs...)))

gplot(net::Network) = gplot(SimpleGraph(net.conmat), nodelabel=1:size(net.conmat, 1))