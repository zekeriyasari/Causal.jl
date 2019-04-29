# This file contains the static systems of JuSDL.

@reexport module StaticSystems

using UUIDs
import ..Systems: infer_number_of_outputs
import ....Components.Base: @generic_static_system_fields, AbstractStaticSystem, AbstractMemory
import ......JuSDL.Utilities: _get_an_element, Callback, Buffer
import ......JuSDL.Connections: Link, Bus


struct StaticSystem{OF, OB} <: AbstractStaticSystem
    @generic_static_system_fields
    function StaticSystem(outputfunc, input, callbacks, name)
        output = outputfunc == nothing ? nothing : Bus(infer_number_of_outputs(outputfunc, zeros(length(input)), 0))
        new{typeof(outputfunc), typeof(output)}(outputfunc, input, output, Link(), callbacks, name)
    end
end
StaticSystem(outputfunc, input; callbacks=Callback[], name=string(uuid4())) = 
    StaticSystem(outputfunc, input, callbacks, name)


struct Adder{OF, OB, S} <: AbstractStaticSystem
    @generic_static_system_fields
    signs::S
    function Adder(signs::Tuple{Vararg{Union{typeof(+), typeof(-)}}}, callbacks, name)
        output = Bus()
        outputfunc(u, t) = sum([sign(val) for (sign, val) in zip(signs, u)])
        new{typeof(outputfunc), typeof(output), typeof(signs)}(outputfunc, Bus(length(signs)), output, Link(), 
        callbacks, name)
    end
end
Adder(signs::Vararg{Union{typeof(+), typeof(-)}}; callbacks=Callback[], name=string(uuid4())) = 
    Adder(signs, callbacks, name)
Adder(;kwargs...) = Adder(+, +; kwargs...)


struct Multiplier{OF, OB, S} <: AbstractStaticSystem
    @generic_static_system_fields
    ops::S
    function Multiplier(ops::Tuple{Vararg{Union{typeof(*), typeof(/)}}}, callbacks, name)
        output = Bus()
        function outputfunc(u, t)
            val = 1
            for i = 1 : length(ops)
                val = op[i](val, u[i])
            end
            val
        end
        new{typeof(outputfunc), typeof(output), typeof(ops)}(outputfunc, Bus(length(ops)), output, Link(), 
        callbacks, name)
    end
end
Multiplier(ops::Vararg{Union{typeof(*), typeof(/)}}; callbacks=Callback[], name=string(uuid4())) = 
    Multiplier(ops, callbacks, name)
Multiplier(;kwargs...) = Multiplier(*, *; kwargs...)


struct Gain{OF, OB, T} <: AbstractStaticSystem
    @generic_static_system_fields
    gain::T
    function Gain(gain::Union{<:AbstractVector, <:AbstractMatrix, <:Real} , callbacks, name)
        output = Bus(size(gain, 1))
        if typeof(gain) <: AbstractVector
            outputfunc = (u, t) -> gain .* u
        else
            outputfunc = (u, t) -> gain * u
        end
        new{typeof(outputfunc), typeof(output), typeof(gain)}(outputfunc, Bus(length(gain)), output, Link(), callbacks, name, gain)
    end
end
Gain(gain=[1.]; callbacks=Callback[], name=string(uuid4())) = Gain(gain, callbacks, name)


struct Memory{OF, OB, B} <: AbstractMemory
    @generic_static_system_fields
    buffer::B 
    scale::Float64
    function Memory(delay, input, scale, x0, callbacks, name)
        numinputs = length(input)
        output = Bus(numinputs)
        input = Bus(numinputs)
        buffer = numinputs == 1 ? Buffer(delay, mode=:fifo) : Buffer(delay, numinputs, mode=:fifo)
        fill!(buffer, x0)
        outputfunc(u, t) = scale * buffer() + (1 - scale) * _get_an_element(buffer, buffer.index - 1)
        new{typeof(outputfunc), typeof(output), typeof(buffer)}(outputfunc, input, output, Link(),  callbacks, name, buffer, scale)
    end
end
Memory(delay=2, input=Bus(); scale=0.01, x0=zero(Float64), callbacks=Callback[], name=string(uuid4())) = 
    Memory(delay, input, scale, x0, callbacks, name)


struct Terminator{OF, OB}
    @generic_static_system_fields
    function Terminator(input, callbacks, name)
        output = nothing
        outputfunc = nothing
        new{typeof(outputfunc), typeof(output)}(outputfunc, input, output, Link(), callbacks, name) 
    end
end 
Terminator(input=Bus(); callbacks=Callback[], name=string(uuid4())) = Terminator(input, callbacks, name)


@deprecate Coupler(E, P) Gain(kron(E, P))


export StaticSystem, Adder, Multiplier, Gain, Memory, Terminator

end  # module