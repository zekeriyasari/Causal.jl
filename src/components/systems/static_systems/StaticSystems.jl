# This file contains the static systems of Jusdl.

@reexport module StaticSystems

using UUIDs
import ..Systems: infer_number_of_outputs, checkandshow, hasargs
import ....Components.Base: @generic_static_system_fields, AbstractStaticSystem, AbstractMemory
import ......Jusdl.Utilities: Callback, Buffer, Fifo
import ......Jusdl.Connections: Link, Bus, Bus
import Base.show


struct StaticSystem{OF, IB, OB, L} <: AbstractStaticSystem
    @generic_static_system_fields
    function StaticSystem(outputfunc, input, output)
        trigger = Link()
        new{typeof(outputfunc), typeof(input), typeof(output), typeof(trigger)}(outputfunc, input, output, trigger, Callback[], uuid4())
    end
end


struct Adder{OF, IB, OB, L, S} <: AbstractStaticSystem
    @generic_static_system_fields
    signs::S
    function Adder(input::Bus, signs::Tuple{Vararg{Union{typeof(+), typeof(-)}}}=tuple(fill(+, length(input))...))
        outputfunc(u, t) = sum([sign(val) for (sign, val) in zip(signs, u)])
        output = Bus{eltype(input)}()
        trigger = Link()
        new{typeof(outputfunc), typeof(input), typeof(output), typeof(trigger), typeof(signs)}(outputfunc, input, output, trigger, Callback[], uuid4(), signs)
    end
end


struct Multiplier{OF, IB, OB, L, S} <: AbstractStaticSystem
    @generic_static_system_fields
    ops::S
    function Multiplier(input::Bus, ops::Tuple{Vararg{Union{typeof(*), typeof(/)}}}=tuple(fill(*, length(input))...))
        function outputfunc(u, t)
            val = 1
            for i = 1 : length(ops)
                val = op[i](val, u[i])
            end
            val
        end
        output = Bus{eltype(input)}()
        trigger = Link()
        new{typeof(outputfunc), typeof(input), typeof(output), typeof(trigger), typeof(ops)}(outputfunc, input, output, trigger, Callback[], uuid4(), ops)
    end
end


struct Gain{OF, IB, OB, L, T} <: AbstractStaticSystem
    @generic_static_system_fields
    gain::T
    function Gain(input::Bus, gain=1.)
        outputfunc(u, t) =  gain * u
        output = Bus{eltype(input)}(length(input))
        trigger = Link()
        new{typeof(outputfunc), typeof(input) , typeof(output), typeof(trigger), typeof(gain)}(outputfunc, input, output, Link(), Callback[], uuid4(), gain)
    end
end


struct Terminator{OF, IB, OB, L} <: AbstractStaticSystem
    @generic_static_system_fields
    function Terminator(input::Bus)
        outputfunc = nothing
        output = nothing
        trigger = Link()
        new{typeof(outputfunc), typeof(input), typeof(output), typeof(trigger)}(outputfunc, input, output, trigger, Callback[], uuid4()) 
    end
end 


struct Memory{OF, IB, OB, B, L} <: AbstractMemory
    @generic_static_system_fields
    buffer::B 
    function Memory(input::Bus{Union{Missing, T}}, numdelay::Int, initial=missing) where T 
        buffer = Buffer{Fifo}(Vector{T}, numdelay)
        fill!(buffer, initial)
        outputfunc(u, t) = buffer()
        output = Bus{eltype(input)}(length(input))
        trigger = Link()
        new{typeof(outputfunc), typeof(input), typeof(output), typeof(buffer), typeof(trigger)}(outputfunc, input, output, Link(), Callback[], uuid4(), buffer)
    end
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
