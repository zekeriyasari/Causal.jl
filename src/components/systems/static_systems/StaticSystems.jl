# This file contains the static systems of Jusdl.

@reexport module StaticSystems

using UUIDs
import ..Systems: infer_number_of_outputs
import ....Components.Base: @generic_static_system_fields, AbstractStaticSystem, AbstractMemory
import ......Jusdl.Utilities: Callback, Buffer, Fifo
import ......Jusdl.Connections: Link, Bus, AbstractBus


struct StaticSystem{OF, IB, OB} <: AbstractStaticSystem
    @generic_static_system_fields
end
function StaticSystem(outputfunc, input::AbstractBus)
    output = outputfunc === nothing ? nothing : Bus{typeof(outputfunc(zeros(length(input)), 0.))}()
    StaticSystem(outputfunc, input, output, Link(), Callback[], uuid4())
end


struct Adder{OF, IB, OB, S} <: AbstractStaticSystem
    @generic_static_system_fields
    signs::S
end
function Adder(input::AbstractBus, signs::Tuple{Vararg{Union{typeof(+), typeof(-)}}}=tuple(fill(+, length(input))...))
    outputfunc(u, t) = sum([sign(val) for (sign, val) in zip(signs, u)])
    output = Bus{typeof(outputfunc(zeros(length(input)), 0.))}()
    Adder(outputfunc, input, output, Link(), Callback[], uuid4(), signs)
end


struct Multiplier{OF, IB, OB, S} <: AbstractStaticSystem
    @generic_static_system_fields
    ops::S
end
function Multiplier(input::AbstractBus, ops::Tuple{Vararg{Union{typeof(*), typeof(/)}}}=tuple(fill(*, length(input))...))
    function outputfunc(u, t)
        val = 1
        for i = 1 : length(ops)
            val = op[i](val, u[i])
        end
        val
    end
    output = Bus{typeof(outputfunc(zeros(length(input)), 0.))}()
    Multiplier(outputfunc, input, output, Link(), Callback[], uuid4(), ops)
end


struct Gain{OF, IB, OB, T} <: AbstractStaticSystem
    @generic_static_system_fields
    gain::T
end
function Gain(input::AbstractBus, gain=[1.])
    outputfunc(u, t) =  gain * u
    output = Bus{typeof(outputfunc(zeros(length(input)), 0.))}()
    Gain(outputfunc, input, output, Link(), Callback[], uuid4(), gain)
end


struct Terminator{OF, IB, OB} <: AbstractStaticSystem
    @generic_static_system_fields
end 
Terminator(input::AbstractBus) = Terminator(nothing, input, nothing, Link(), Callback[], uuid4()) 


struct Memory{OF, IB, OB, B, S} <: AbstractMemory
    @generic_static_system_fields
    buffer::B 
    scale::S
end
# Memory(input::AbstractBus, ln::Int, scale=0.01)

export StaticSystem, Adder, Multiplier, Gain, Terminator, Memory
# export StaticSystem, Adder, Multiplier, Gain, Memory, Terminator

end  # module