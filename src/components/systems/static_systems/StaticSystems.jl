# This file contains the static systems of Jusdl.

@reexport module StaticSystems

using UUIDs
import ..Systems: infer_number_of_outputs, checkandshow, hasargs
import ....Components.Base: @generic_system_fields, @generic_static_system_fields, AbstractStaticSystem, AbstractMemory
import ......Jusdl.Utilities: Callback, Buffer, Fifo
import ......Jusdl.Connections: Link, Bus, Bus
import Base.show


struct StaticSystem{IB, OB, T, H, OF} <: AbstractStaticSystem
    @generic_static_system_fields
    function StaticSystem(input, output, outputfunc)
        trigger = Link()
        handshake = Link{Bool}()
        new{typeof(input), typeof(output), typeof(trigger), typeof(handshake), typeof(outputfunc)}(input, output, trigger, handshake, Callback[], uuid4(), outputfunc)
    end
end


struct Adder{IB, OB, T, H, OF, S} <: AbstractStaticSystem
    @generic_static_system_fields
    signs::S
    function Adder(input::Bus, signs::Tuple{Vararg{Union{typeof(+), typeof(-)}}}=tuple(fill(+, length(input))...))
        outputfunc(u, t) = sum([sign(val) for (sign, val) in zip(signs, u)])
        output = Bus{eltype(input)}()
        trigger = Link()
        handshake = Link{Bool}()
        new{typeof(input), typeof(output), typeof(trigger), typeof(handshake), typeof(outputfunc), typeof(signs)}(input,
        output, trigger, handshake, Callback[], uuid4(), outputfunc, signs)
    end
end


struct Multiplier{IB, OB, T, H, OF, S} <: AbstractStaticSystem
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
        handshake = Link{Bool}()
        new{typeof(input), typeof(output), typeof(trigger), typeof(handshake), typeof(outputfunc), typeof(ops)}(input, 
        output, trigger, handshake, Callback[], uuid4(), outputfunc, ops)
    end
end


struct Gain{IB, OB, T, H, OF, G} <: AbstractStaticSystem
    @generic_static_system_fields
    gain::G
    function Gain(input::Bus; gain=1.)
        outputfunc(u, t) =  gain * u
        output = Bus{eltype(input)}(length(input))
        trigger = Link()
        handshake = Link{Bool}()
        new{typeof(input), typeof(output), typeof(trigger), typeof(handshake), typeof(outputfunc), typeof(gain)}(input, 
            output, trigger, handshake, Callback[], uuid4(), outputfunc, gain)
    end
end


struct Terminator{IB, OB, T, H, OF} <: AbstractStaticSystem
    @generic_static_system_fields
    function Terminator(input::Bus)
        outputfunc = nothing
        output = nothing
        trigger = Link()
        handshake = Link{Bool}()
        new{typeof(input), typeof(output), typeof(trigger), typeof(handshake), typeof(outputfunc)}(input, output, 
            trigger, handshake, Callback[], uuid4(), outputfunc) 
    end
end 


struct Memory{IB, OB, T, H, OF, B} <: AbstractMemory
    @generic_static_system_fields
    buffer::B 
    function Memory(input::Bus{Union{Missing, T}}, numdelay::Int; initial=Vector{T}(undef, length(input))) where T 
        buffer = Buffer{Fifo}(Vector{T}, numdelay)
        fill!(buffer, initial)
        outputfunc(u, t) = buffer()
        output = Bus{eltype(input)}(length(input))
        trigger = Link()
        handshake = Link{Bool}()
        new{typeof(input), typeof(output), typeof(trigger), typeof(handshake), typeof(outputfunc), 
            typeof(buffer)}(input, output, trigger, handshake, Callback[], uuid4(), outputfunc, buffer)
    end
end


struct Coupler{IB, OB, T, H, OF, C1, C2} <: AbstractStaticSystem
    @generic_static_system_fields
    conmat::C1
    cplmat::C2
    function Coupler(conmat::AbstractMatrix, cplmat::AbstractMatrix)
        n = size(conmat, 1)
        d = size(cplmat, 1)
        input = Bus(n * d)
        output = Bus(n * d)
        if eltype(conmat) <: Real 
            outputfunc = (u, t) -> kron(conmat, cplmat) * u     # Time invariant coupling
        else
            outputfunc = (u, t) -> kron(map(f->f(t), conmat), cplmat) * u  # Time varying coupling 
        end
        trigger = Link()
        handshake = Link{Bool}()
        new{typeof(input), typeof(output), typeof(trigger), typeof(handshake), typeof(outputfunc), typeof(conmat), 
            typeof(cplmat)}(input, output, trigger, handshake, Callback[], uuid4(), outputfunc, conmat, cplmat)
    end
end

# ##### Pretty-printing
show(io::IO, ss::StaticSystem) = print(io, 
    "StaticSystem(outputfunc:$(ss.outputfunc), input:$(checkandshow(ss.input)), output:$(checkandshow(ss.output)))")
show(io::IO, ss::Adder) = print(io, 
    "Adder(signs:$(ss.signs), input:$(checkandshow(ss.input)), output:$(checkandshow(ss.output)))")
show(io::IO, ss::Multiplier) = print(io, 
    "Multiplier(ops:$(ss.ops), input:$(checkandshow(ss.input)), output:$(checkandshow(ss.output)))")
show(io::IO, ss::Gain) = print(io, 
    "Gain(gain:$(ss.gain), input:$(checkandshow(ss.input)), output:$(checkandshow(ss.output)))")
show(io::IO, ss::Terminator) = print(io, "Gain(input:$(checkandshow(ss.input)), output:$(checkandshow(ss.output)))")
show(io::IO, ss::Memory) = print(io, 
    "Memory(ndelay:$(length(ss.buffer)), input:$(checkandshow(ss.input)), output:$(checkandshow(ss.output)))")
show(io::IO, ss::Coupler) = print(io, "Coupler(conmat:$(ss.conmat), cplmat:$(ss.cplmat))")


export StaticSystem, Adder, Multiplier, Gain, Terminator, Memory, Coupler

end  # module
