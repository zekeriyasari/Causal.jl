# This file contains the DouBuffer type for data buffering.

using UUIDs
import Base: getindex, setindex!, size, eltype, similar
import Base: read, isempty, convert


mutable struct DoubleBuffer{T, N, B, CB} <: AbstractDoubleBuffer{T, N}
    input_buffer::B
    output_buffer::B
    mode::Symbol
    callbacks::CB
    name::String
    function DoubleBuffer(input_buffer::B, output_buffer::B, callbacks::CB,
        name::String) where {B<:AbstractBuffer{T, N},
        CB<:AbstractVector{<:AbstractCallback}} where {T, N}
        input_buffer_mode = mode(input_buffer)
        output_buffer_mode = mode(output_buffer)
        if input_buffer_mode != output_buffer_mode
            msg = "Expected same internal buffer modes, "
            msg *= "got $input_buffer_mode and $output_buffer_mode instead."
            error(msg)
        end
        # Construct the swap callback. This callback
        condition(dbuf) = isfull(dbuf.input_buffer)
        action(dbuf) = swap_buffers(dbuf)
        clb = Callback(condition, action)
        callbacks = [clb, callbacks...]
        new{T, N, B, typeof(callbacks)}(input_buffer, output_buffer, input_buffer_mode,
            callbacks, name)
    end
end
DoubleBuffer(::Type{T}, shape::NTuple{N, Int}; mode=:cyclic, callbacks=Callback[],
    name=randstring()) where {T, N} =
    DoubleBuffer(Buffer(T, shape, mode=mode), Buffer(T, shape, mode=mode), callbacks, name)
DoubleBuffer(::Type{T}, shape::Int...; kwargs...) where T = DoubleBuffer(T,shape;kwargs...)
DoubleBuffer(shape::Int...; kwargs...) = DoubleBuffer(Float64, shape...; kwargs...)

"""
    DoubleBuffer(::Type{T}, shape::NTuple{N, Int}; mode::Symbol=:cyclic,
        callbacks::C=()) where {T<:Real, N, C<:Tuple{Vararg{<:AbstractCallback}}}

Constructs a `DoubleBuffer` consisting of two internal cyclic buffers of size `shape` i.e.
input buffer and output buffer. The data is written to the DoubleBuffer through its input
buffer, and read from through its output buffer. When the input buffer is full, the input
and output buffers are swapped, i.e., the input buffer becomes the output buffer and the
output buffer becomes the input buffer. During swapping, `internal_swap_callback` that is a
0-argument function, is callled. The input and output buffers are distinguished with `mask`
of the DoubleBuffer.

    DoubleBuffer(shape::Int...; kwargs...)

Constructs a `DoubleBuffer` with internal buffers having element type of `Float64`.

    DoubleBuffer()

Constructs `DoubleBuffer` with default values.
"""
function DoubleBuffer end

# Make DoubleBuffer indexable
size(dbuf::DoubleBuffer) = size(dbuf.input_buffer)
getindex(dbuf::DoubleBuffer{T, N, B, CB}, I::Vararg{Int, N}) where {T, N, B, CB} =
    dbuf.output_buffer[I...]
function setindex!(dbuf::DoubleBuffer{T, N, B, CB}, val, I::Vararg{Int, N}) where
    {T, N, B, CB}
    # If the 'setindex!` method is defines for DouleBuffer, than buf[[idx1,...,idxN]] = arr
    # is possible and this makes true update of the buffer index unmanagable. So `write`
    # function should be used.
    @warn "`dbuf[I] = val` has been deprecated. Use `write!(buf, val)`, instead."
    # dbuf.input_buffer[I...] = val
end

eltype(dbuf::DoubleBuffer) = eltype(dbuf.input_buffer)

"""
    swap_buffers(dbuf::DoubleBuffer)

Swaps the input buffer and output buffer of `dbuf`.
"""
function swap_buffers(dbuf::DoubleBuffer)
    hold = dbuf.input_buffer
    dbuf.input_buffer = dbuf.output_buffer
    dbuf.output_buffer = hold
    clean!(dbuf.input_buffer)
end

# Writing into DoubleBuffer
"""
    write!(dbuf::DoubleBuffer{M, T, N, B1, B2, CB}, val::Array{T, N})

Writes `val` to dbuf.

!!! note

    Writing to DoubleBuffer is always performed by writing into its current input buffer.
"""
function write!(dbuf::DoubleBuffer, val)
    write!(dbuf.input_buffer, val)
    dbuf.callbacks(dbuf)
    val
end

# Reading from DoubleBuffer
"""
    read(dbuf::DoubleBuffer)

Reads an element from `dbuf.

!!! note

    Reading from DoubleBuffer is always performed by reading from its current output buffer.
"""
function read(dbuf::DoubleBuffer)
    val = read(dbuf.output_buffer)
    dbuf.callbacks(dbuf)
    val
end

# Calling DoubleBuffer
(dbuf::DoubleBuffer)() = read(dbuf)

# Buffer state checks
"""
    isempty(dbuf::DoubleBuffer)

Returns `true` if input buffer of `dbuf` is empty.
"""
isempty(dbuf::DoubleBuffer) = isempty(dbuf.input_buffer)

"""
    isfull(buf::DoubleBuffer)

Returns `true` if input buffer of `dbuf` is full.
"""
isfull(dbuf::DoubleBuffer) = isfull(dbuf.input_buffer)

"""
    content(dbuf::DoubleBuffer; flip::Bool=true)

Returns the content of the input buffer of `dbuf`. If `flip` is `true`, reversed content
of the input buffer is returned.
"""
content(dbuf::DoubleBuffer; flip::Bool=true) = content(dbuf.output_buffer, flip=flip)

"""
    clean!(dbuf::DoubleBuffer{M, T, N, B1, B2, CB}, val=zero(T)) where {M, T, N, B1, B2, CB}

Cleans both input and output buffers of `dbuf`.
"""
function clean!(dbuf::DoubleBuffer, val)
    clean!(dbuf.input_buffer, val)
    clean!(dbuf.output_buffer, val)
end

"""
    mode(buf::AbstractBuffer{T, N})

Returns mode of `buf`.
"""
mode(dbuf::DoubleBuffer) = mode(dbuf.input_buffer)

"""
    snapshot(dbuf::DoubleBuffer)

Returns data of `output_buffer` of `dbuf`.
"""
snapshot(dbuf::DoubleBuffer) = snapshot(dbuf.output_buffer)

"""
    similar(dbuf, [_eltype, [dims]])

Constructs a new `DoubleBuffer` object similar to `dbuf` with element type `_eltype` and size `dims`.
"""
similar(dbuf::DoubleBuffer, _eltype::Type{T}=eltype(dbuf), dims::Dims=size(dbuf)) where T = DoubleBuffer(T, dims)

# Deprications
@deprecate inbuf(dbuf) dbuf.input_buffer
@deprecate outbuf(dbuf) dbuf.output_buffer
