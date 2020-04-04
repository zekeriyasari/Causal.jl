# This file includes SubSystem for interconnected subsystems.


"""
    SubSystem(components, input, output)

Constructs a `SubSystem` consisting of `components`. `input` and `output` determines the inpyt and output of `SubSystem`. `input` and `output` may be of type `Nothing`, `Bus` of `Vector{<:Link}`.
"""
mutable struct SubSystem{IB, OB, TR, HS, CB, CP} <: AbstractSubSystem
    @generic_system_fields
    components::CP
    function SubSystem(components, input, output, callbacks=nothing, name=Symbol())
        trigger = Inpin()
        handshake = Outpin{Bool}()
        inputport = typeof(input) <: AbstractVector{<:Inpin} ? Inport(input) : input  
        outputport = typeof(output) <: AbstractVector{<:Outpin} ? Outport(output) : output
        # TODO: Check if there exists an unconnected interconnected buses between the components of the subsytem.
        new{typeof(inputport), typeof(outputport), typeof(trigger), typeof(handshake), typeof(callbacks), 
            typeof(components)}(inputport, outputport, trigger, handshake, callbacks, name, uuid4(), components)
    end
end


show(io::IO, sub::SubSystem) = print(io, "SubSystem(input:$(sub.input), ",
    "output:$(sub.output), components:$(sub.components))")
