# This file includes SubSystem for interconnected subsystems.


# TODO: Check if there exists an unconnected interconnected buses between the components of the subsytem.
"""
    SubSystem(components, input, output; callbacks=nothing, name=Symbol())

Constructs a `SubSystem` consisting of `components`. `input` and `output` determines the input and output of `SubSystem`. `input` and `output` may be nothing, a vector of pins or a port.

# Example 
```jldoctest 
julia> adder = Adder((+,-));

julia> gain = Gain();

julia> gen = ConstantGenerator();

julia> connect(gen.output, adder.input);

julia> connect(adder.output, gain.input);

julia> ss = SubSystem([gen, adder, gain], adder.input[1], gain.output)
SubSystem(input:Inport(numpins:1, eltype:Inpin{Float64}), output:Outport(numpins:1, eltype:Outpin{Float64}), components:AbstractComponent[ConstantGenerator(amp:1.0), Adder(signs:(+, -), input:Inport(numpins:2, eltype:Inpin{Float64}), output:Outport(numpins:1, eltype:Outpin{Float64})), Gain(gain:1.0, input:Inport(numpins:1, eltype:Inpin{Float64}), output:Outport(numpins:1, eltype:Outpin{Float64}))])
```
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
        inputport = typeof(input) <: Union{<:Inpin, AbstractVector{<:Inpin}} ? Inport(input) : input  
        outputport = typeof(output) <: Union{<:Outpin, AbstractVector{<:Outpin}} ? Outport(output) : output
        new{typeof(inputport), typeof(outputport), typeof(trigger), typeof(handshake), typeof(callbacks), 
            typeof(components), typeof(triggerport), typeof(handshakeport)}(inputport, outputport, trigger, handshake, callbacks, name, uuid4(), components, triggerport, handshakeport)
    end
end

show(io::IO, sub::SubSystem) = print(io, "SubSystem(input:$(sub.input), ",
    "output:$(sub.output), components:$(sub.components))")
