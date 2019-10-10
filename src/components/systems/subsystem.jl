
import ....Components.Base: @generic_system_fields, AbstractSystem, Callback, Link, Bus


mutable struct Subsystem{IB, OB, L, C} <: AbstractSystem
    @generic_system_fields
    components::C
    function Subsystem(components, input::Union{Nothing, <:Bus, <:AbstractVector{<:Link}}, output::Union{Nothing, <:Bus, <:AbstractVector{<:Link}})
        trigger = Link()
        if typeof(input) <: AbstractVector{<:Link}
            inputbus = Bus(length(input))
            inputbus .= input
        else 
            inputbus = input
        end
        
        if typeof(output) <: AbstractVector{<:Link}
            outputbus = Bus(length(output))
            outputbus .= output
        else
            outputbus = output
        end
        new{typeof(input), typeof(output), typeof(trigger), typeof(components)}(inputbus, outputbus, trigger, 
            Callback[], uuid4(), components)
    end
end

show(io::IO, sub::Subsystem) = print(io, "Subsystem(input:$(checkandshow(sub.input)), ",
    "output:$(checkandshow(sub.output)), components:$(checkandshow(sub.components)))")
