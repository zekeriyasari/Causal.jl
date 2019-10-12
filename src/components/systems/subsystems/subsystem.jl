# This file includes SubSystem for interconnected subsystems.


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


show(io::IO, sub::SubSystem) = print(io, "SubSystem(input:$(checkandshow(sub.input)), ",
    "output:$(checkandshow(sub.output)), components:$(checkandshow(sub.components)))")
