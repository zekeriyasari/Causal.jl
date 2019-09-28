# This file contains the static systems of Jusdl.

@reexport module StaticSystems

using UUIDs
import ..Systems: infer_number_of_outputs, checkandshow
import ....Components.Base: @generic_static_system_fields, AbstractStaticSystem, AbstractMemory
import ......Jusdl.Utilities: Callback, Buffer, Fifo
import ......Jusdl.Connections: Link, Bus, AbstractBus
import Base.show


struct StaticSystem{OF, IB, L, OB} <: AbstractStaticSystem
    @generic_static_system_fields
end
StaticSystem(outputfunc, input, output) = StaticSystem(outputfunc, input, output, Link(), Callback[], uuid4())


struct Adder{OF, IB, OB, L, S} <: AbstractStaticSystem
    @generic_static_system_fields
    signs::S
end
function Adder(input::AbstractBus, signs::Tuple{Vararg{Union{typeof(+), typeof(-)}}}=tuple(fill(+, length(input))...))
    outputfunc(u, t) = sum([sign(val) for (sign, val) in zip(signs, u)])
    output = Bus{eltype(input)}()
    Adder(outputfunc, input, output, Link(), Callback[], uuid4(), signs)
end


struct Multiplier{OF, IB, OB, L, S} <: AbstractStaticSystem
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
    output = Bus{eltype(input)}()
    Multiplier(outputfunc, input, output, Link(), Callback[], uuid4(), ops)
end


struct Gain{OF, IB, OB, L, T} <: AbstractStaticSystem
    @generic_static_system_fields
    gain::T
end
function Gain(input::AbstractBus, gain=1.)
    outputfunc(u, t) =  gain * u
    output = Bus{eltype(input)}(length(input))
    Gain(outputfunc, input, output, Link(), Callback[], uuid4(), gain)
end


struct Terminator{OF, IB, OB, L} <: AbstractStaticSystem
    @generic_static_system_fields
end 
Terminator(input::AbstractBus) = Terminator(nothing, input, nothing, Link(), Callback[], uuid4()) 


struct Memory{OF, IB, OB, B, L} <: AbstractMemory
    @generic_static_system_fields
    buffer::B 
end
function Memory(input::AbstractBus, numdelay::Int)
    buffer = Buffer{Fifo}(eltype(input), numdelay)
    outputfunc(u, t) = buffer()
    output = Bus{eltype(input)}(length(input))
    Memory(outputfunc, input, output, Link(), Callback[], uuid4(), buffer)
end

##### Pretty-printing
show(io::IO, ss::StaticSystem) = print(io, "StaticSystem(outputfunc:$(ss.outputfunc), input:$(checkandshow(ss.input)), output:$(checkandshow(ss.output)))")
show(io::IO, ss::Adder) = print(io, "Adder(signs:$(ss.signs), input:$(checkandshow(ss.input)), output:$(checkandshow(ss.output))")
show(io::IO, ss::Multiplier) = print(io, "Multiplier(ops:$(ss.ops), input:$(checkandshow(ss.input)), output:$(checkandshow(ss.output))")
show(io::IO, ss::Gain) = print(io, "Gain(gain:$(ss.gain), input:$(checkandshow(ss.input)), output:$(checkandshow(ss.output))")
show(io::IO, ss::Terminator) = print(io, "Gain(input:$(checkandshow(ss.input)), output:$(checkandshow(ss.output))")
show(io::IO, ss::Memory) = print(io, "Memory(ndelay:$(length(ss.buffer)), input:$(checkandshow(ss.input)), output:$(checkandshow(ss.output))")


export StaticSystem, Adder, Multiplier, Gain, Terminator, Memory

end  # module
