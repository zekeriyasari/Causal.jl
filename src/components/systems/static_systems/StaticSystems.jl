# This file contains the static systems of JuSDL.

@reexport module StaticSystems

using UUIDs
import ..Systems: infer_number_of_outputs
import ....Components.Base: @generic_static_system_fields, AbstractStaticSystem, AbstractMemory
import ......JuSDL.Utilities: Callback, Buffer, Fifo
import ......JuSDL.Connections: Link, Bus, AbstractBus


struct StaticSystem{OF, IB, OB} <: AbstractStaticSystem
    @generic_static_system_fields
end
function StaticSystem(outputfunc, input::AbstractBus)
    output = outputfunc === nothing ? nothing : Bus{typeof(outputfunc(zeros(length(input)), 0.))}()
    StaticSystem(outputfunc, input, output, Link(), Callback[], uuid4())
end


# struct Adder{OF, OB, S} <: AbstractStaticSystem
#     @generic_static_system_fields
#     signs::S
#     function Adder(signs::Tuple{Vararg{Union{typeof(+), typeof(-)}}})
#         output = Bus()
#         outputfunc(u, t) = sum([sign(val) for (sign, val) in zip(signs, u)])
#         new{typeof(outputfunc), typeof(output), typeof(signs)}(outputfunc, Bus(length(signs)), output, Link(), Callback[], uuid4(), signs)
#     end
# end
# Adder(signs::Vararg{Union{typeof(+), typeof(-)}}) = Adder(signs)
# Adder(;kwargs...) = Adder(+, +; kwargs...)


# struct Multiplier{OF, OB, S} <: AbstractStaticSystem
#     @generic_static_system_fields
#     ops::S
#     function Multiplier(ops::Tuple{Vararg{Union{typeof(*), typeof(/)}}})
#         output = Bus()
#         function outputfunc(u, t)
#             val = 1
#             for i = 1 : length(ops)
#                 val = op[i](val, u[i])
#             end
#             val
#         end
#         new{typeof(outputfunc), typeof(output), typeof(ops)}(outputfunc, Bus(length(ops)), output, Link(), Callback[], uuid4(), ops)
#     end
# end
# Multiplier(ops::Vararg{Union{typeof(*), typeof(/)}}) = Multiplier(ops)
# Multiplier(;kwargs...) = Multiplier(*, *; kwargs...)


# struct Gain{OF, OB, T} <: AbstractStaticSystem
#     @generic_static_system_fields
#     gain::T
#     function Gain(gain::Union{<:AbstractVector, <:AbstractMatrix, <:Real})
#         output = Bus(size(gain, 1))
#         if typeof(gain) <: AbstractVector
#             outputfunc = (u, t) -> gain .* u
#         else
#             outputfunc = (u, t) -> gain * u
#         end
#         new{typeof(outputfunc), typeof(output), typeof(gain)}(outputfunc, Bus(size(gain, 2)), output, Link(), Callback[], uuid4(), gain)
#     end
# end
# Gain(gain=[1.]) = Gain(gain)


# struct Memory{OF, OB, B} <: AbstractMemory
#     @generic_static_system_fields
#     buffer::B 
#     scale::Float64
#     function Memory(delay, input, scale, x0)
#         numinputs = length(input)
#         output = Bus(numinputs)
#         input = Bus(numinputs)
#         buffer = numinputs == 1 ? Buffer{Fifo}(delay) : Buffer{Fifo}(delay, numinputs)
#         fill!(buffer, x0)
##         outputfunc(u, t) = scale * buffer() + (1 - scale) * getelement(buffer, buffer.index - 1)
#         outputfunc(u, t) = scale * buffer() + (1 - scale) * buffer[buffer.index - 1]
#         new{typeof(outputfunc), typeof(output), typeof(buffer)}(outputfunc, input, output, Link(), Callback[], uuid4(), buffer, scale)
#     end
# end
# Memory(delay=2, input=Bus(); scale=0.01, x0=zero(Float64)) = Memory(delay, input, scale, x0)


# struct Terminator{OF, OB} <: AbstractStaticSystem
#     @generic_static_system_fields
#     function Terminator(input)
#         output = nothing
#         outputfunc = nothing
#         new{typeof(outputfunc), typeof(output)}(outputfunc, input, output, Link(), Callback[], uuid4()) 
#     end
# end 
# Terminator() = Terminator(Bus())

export StaticSystem
# export StaticSystem, Adder, Multiplier, Gain, Memory, Terminator

end  # module