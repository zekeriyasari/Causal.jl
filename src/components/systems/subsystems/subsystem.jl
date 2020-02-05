# This file includes SubSystem for interconnected subsystems.


"""
    SubSystem(components, input, output)

Constructs a `SubSystem` consisting of `components`. `input` and `output` determines the inpyt and output of `SubSystem`. `input` and `output` may be of type `Nothing`, `Bus` of `Vector{<:Link}`.
"""
mutable struct SubSystem{IB, OB, T, H, C} <: AbstractSubSystem
    @generic_system_fields
    components::C
    function SubSystem(components, input::Union{Nothing, <:Bus, <:AbstractVector{<:Link}}, 
        output::Union{Nothing, <:Bus, <:AbstractVector{<:Link}})
        trigger = Link()
        handshake = Link(Bool)
        if typeof(input) <: AbstractVector{<:Link}
            # inputbus = Bus(length(input))
            # for (i, link) in enumerate(input)
            #     inputbus[i] = link
            # end
            # inputbus .= input
            inputbus = Bus(input)  # Wrap input directly to construct a bus.
        else 
            inputbus = input
        end
        
        if typeof(output) <: AbstractVector{<:Link}
            # outputbus = Bus(length(output))
            # for (i, link) in enumerate(output)
            #     outputbus[i] = link
            # end
            # outputbus .= output
            outputbus = Bus(output)  # Wrap output directly to construct a bus.
        else
            outputbus = output
        end
        # TODO: Check if there exists an unconnected interconnected buses between the components of the subsytem.
        new{typeof(inputbus), typeof(outputbus), typeof(trigger), typeof(handshake), typeof(components)}(inputbus, 
            outputbus, trigger, handshake, Callback[], uuid4(), components)
    end
end


show(io::IO, sub::SubSystem) = print(io, "SubSystem(input:$(checkandshow(sub.input)), ",
    "output:$(checkandshow(sub.output)), components:$(checkandshow(sub.components)))")
