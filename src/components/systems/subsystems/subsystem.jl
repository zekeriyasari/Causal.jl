# This file includes SubSystem for interconnected subsystems.


# TODO: Check if there exists an unconnected interconnected buses between the components of the subsytem.
"""
    SubSystem(components, input, output)

Constructs a `SubSystem` consisting of `components`. `input` and `output` determines the inpyt and output of `SubSystem`. `input` and `output` may be of type `Nothing`, `Bus` of `Vector{<:Link}`.
"""
mutable struct SubSystem{IB, OB, TR, HS, CB, CP, TP, HP} <: AbstractSubSystem
    @generic_system_fields
    components::CP
    triggerport::TP 
    handshakeport::HP
    function SubSystem(components, input, output; callbacks=nothing, name=Symbol())
        trigger = Inpin()
        handshake = Outpin{Bool}()
        numcomps = length(components)
        triggerport = Outport(numcomps)
        handshakeport = Inport{Bool}(numcomps)
        for (k, component) in enumerate(components)
            connect(triggerport[k], component.trigger)
            connect(component.handshake, handshakeport[k])
        end
        inputport = typeof(input) <: AbstractVector{<:Inpin} ? Inport(input) : input  
        outputport = typeof(output) <: AbstractVector{<:Outpin} ? Outport(output) : output
        new{typeof(inputport), typeof(outputport), typeof(trigger), typeof(handshake), typeof(callbacks), 
            typeof(components), typeof(triggerport), typeof(handshakeport)}(inputport, outputport, trigger, handshake, callbacks, name, uuid4(), components, triggerport, handshakeport)
    end
end

show(io::IO, sub::SubSystem) = print(io, "SubSystem(input:$(sub.input), ",
    "output:$(sub.output), components:$(sub.components))")
