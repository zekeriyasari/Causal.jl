# This file includes SubSystem for interconnected subsystems.

import ....Components.Base: @generic_system_fields, AbstractSubSystem
import ....Components.Systems.StaticSystems: Memory, Coupler
import ......Jusdl.Connections: Link, Bus, connect
import ......Jusdl.Utilities: Callback


mutable struct SubSystem{IB, OB, L, C} <: AbstractSubSystem
    @generic_system_fields
    components::C
    function SubSystem(components, input::Union{Nothing, <:Bus, <:AbstractVector{<:Link}}, 
        output::Union{Nothing, <:Bus, <:AbstractVector{<:Link}})
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
        # TODO: Check if there exists an unconnected interconnected buses between the components of the subsytem.
        new{typeof(inputbus), typeof(outputbus), typeof(trigger), typeof(components)}(inputbus, outputbus, trigger, 
            Callback[], uuid4(), components)
    end
end


mutable struct Network{IB, OB, L, C, T, S} <: AbstractSubSystem
    @generic_system_fields
    components::C
    adjmat::T 
    cplmat::S 
    function Network(components, adjmat, cplmat, input=nothing, output=vcat([component.output.links for component in components]...))
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
        numnodes = typeof(adjmat) <: AbstractMatrix ? size(adjmat, 1) : size(adjmat(0.), 1) 
        dimnodes = size(cplmat, 1)
        coupler = Coupler(adjmat, cplmat)
        memories = [Memory(Bus(dimnodes), 2, zeros(dimnodes)) for i = 1 : numnodes]
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
        new{typeof(inputbus), typeof(outputbus), typeof(trigger), typeof(allcomponents), typeof(adjmat), typeof(cplmat)}(inputbus, 
            outputbus, trigger, Callback[], uuid4(), allcomponents, adjmat, cplmat)
    end
end

show(io::IO, sub::SubSystem) = print(io, "SubSystem(input:$(checkandshow(sub.input)), ",
    "output:$(checkandshow(sub.output)), components:$(checkandshow(sub.components)))")
show(io::IO, net::Network) = print(io, "Network(adjmat:$(checkandshow(net.adjmat)), cplmat:$(checkandshow(net.cplmat))",
    "input:$(checkandshow(net.input)), output:$(checkandshow(net.output)))")
