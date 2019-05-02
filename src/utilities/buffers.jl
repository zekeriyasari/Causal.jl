# This file constains the Buffer for data buffering.

using UUIDs
import Base: getindex, setindex!, size, read, isempty, fill!, setproperty!, similar

const buffer_modes = [:normal, :cyclic, :lifo, :fifo]

"""
    Buffer{T, N} <: AbstractBuffer{T, N}

`N` dimensional `Buffer` with element type `T`.

    Buffer(::Type{T}, shape::Int...; [mode::Symbol, [callbacks::Vector{Callback}, [name;;String]]])

Constructs a `Buffer` of shape `shape` and element type `T`. `callbacks` is the vector of additional callbacks for event monitoring capability and `name` is the name of `Buffer`. `mode` is the mode of the buffer with the following properties:

* `normal`: Data can be written into buffer until the buffer is full. When the buffer is full, no more writing is possible. When read, the last written element is returned without deleting the returned element.

* `cyclic`: Data can be written into buffer until the buffer is full. When the buffer is full, data is written into the the buffer after shifting the buffer data to right. When read, the last written element is returned without deleting the returned element.

* `lifo`: Data can be written into buffer until the buffer is full. When the buffer is full, no more writing is possible. When read, last element written to the buffer is returned by deleting the returned element.

* `fifo`: Data can be written into buffer until the buffer is full. When the buffer is full, no more writing is possible. When read, fist element written to the buffer is returned by deleting the returned element.


    Buffer(shape::Int..., [mode::Symbol, [callbacks::Vector{Callback}, [name::String]]])
Constructs a `Buffer of shape `shape`
"""
mutable struct Buffer{T, N} <: AbstractBuffer{T, N}
    data::Array{T, N}               # Internal data container
    index::Int                      # Indicator that indicates up to where the data is written into buffer 
    mode::Symbol                    # Mode of the buffer. Can be `normal`, `cyclic`, `lifo`, `fifo`
    status::Symbol                  # Status of the buffer. Can be `empty`, `nonempty`, `full`.
    callbacks::Vector{Callback}     # Vector of callbacks for event monitoring.
    name::String                    # Name
    function Buffer(data::Array{T, N}, mode, callbacks, name) where {T, N}
        if mode in buffer_modes
            new{T, N}(data, 1, mode, :empty, callbacks, name)
        else
            error("Expected $(buffer_modes) got $mode")
        end
    end
end
Buffer(::Type{T}, shape::NTuple{N, Int}; mode=:cyclic, callbacks=Callback[], name=string(uuid4())) where {T, N} = 
    Buffer(Array{T,N}(undef, shape...), mode, callbacks, name)
Buffer(::Type{T}, shape::Int...; kwargs...) where T = Buffer(T, shape; kwargs...)
Buffer(shape::Int...; kwargs...) = Buffer(Float64, shape...; kwargs...)

function setproperty!(buf::Buffer, name::Symbol, val::Int)
    if name == :index
        if val < 1
            error("Buffer index cannot be less than 1.")
        end
        setfield!(buf, name, val)
        if val == 1
            buf.status = :empty
        elseif val > size(buf.data, 1)
            buf.status = :full
        else
            buf.status = :nonempty
        end
    end
end

##### AbstractArray Interface.
size(buf::Buffer) = size(buf.data)
getindex(buf::Buffer{T, N}, idx::Vararg{Int, N}) where {T, N} = getindex(buf.data[idx...])
setindex!(buf::Buffer, val, inds::Vararg{Int, N}) where {T, N} = (buf.data[inds...] = val)

##### Writing into buffers
function _write_without_size_check(buf::Buffer, val::AbstractArray)
    n = size(val, 1)
    buf.data .= circshift(buf.data, n)
    buf.data[1:n, :] = val
    buf.index += n
    return
end

function _write_with_size_check(buf::Buffer, val::AbstractArray)
    if isfull(buf)
        @warn "Buffer is full, no more appends are allowed"
    else
        _write_without_size_check(buf, val)
    end
end


function write!(buf::Buffer, val::Array)
    if buf.mode == :cyclic
        _write_without_size_check(buf, val)
        isfull(buf) && setfield!(buf, :index, %(buf.index, size(buf.data, 1)))
    else
        _write_without_size_check(buf, val)
    end
    buf.callbacks(buf)
    val
end
write!(buf::Buffer, val::Real) = (write!(buf, [val]); val)
write!(buf::Buffer{T, 2}, val::Vector) where {M, T} = write!(buf, hcat(val...))


##### Reading from buffers.
_get_an_element(buf::Buffer{T, 1}, idx::Int) where {T} = buf.data[idx]
_get_an_element(buf::Buffer{T, N}, idx::Int) where {T, N} = buf.data[idx, :]
_set_an_element(buf::Buffer{T, 1}, idx::Int) where {T} = (buf.data[idx] = zero(T))
_set_an_element(buf::Buffer{T, N}, idx::Int) where {T, N} = (buf.data[idx, :] = zeros(T, size(buf, 2)))

function read(buf::Buffer)
    if isempty(buf)
        @warn "Buffer is empty, no more elements to read"
        return
    end

    mode = buf.mode
    if mode == :normal || mode == :cyclic
        val = _get_an_element(buf, 1)  # Read from the top of the buffer.
    elseif mode == :fifo
        buf.index -= 1
        val = _get_an_element(buf, buf.index)  # Read from the bottom of the buffer.
        _set_an_element(buf, buf.index)
    elseif mode == :lifo
        val = _get_an_element(buf, 1)
        buf.data .= circshift(buf, -1)
        _set_an_element(buf, length(buf))
        buf.index -= 1
    end
    buf.callbacks(buf)
    val
end

##### Buffer status checks
isempty(buf::Buffer) = buf.status == :empty
isfull(buf::Buffer) = buf.status == :full

function clean!(buf::Buffer{T, N}, val=zero(T)) where {T, N}
    fill!(buf.data, val)
    buf.index = 1
    buf
end

function fill1d!(buf, val)
    n = length(buf)
    foreach(row -> write!(buf, [val]), 1 : n)
    buf
end

function fill2d!(buf, val)
    nrows, ncols = size(buf)
    foreach(row -> write!(buf, fill(val, ncols)), 1 : nrows)
    buf
end

function fill!(buf::Buffer{T, N}, val=zero(T)) where {T, N}
    _ndims = ndims(buf)
    if _ndims == 1
        fill1d!(buf, val)
    elseif _ndims == 2
        fill2d!(buf, val)
    else
        error("Expected at most 2 dimensional buffers, got $_ndims")
    end
end

function content(buf::Buffer; flip::Bool=true)
    if isempty(buf)
        return nothing
    end
    if isfull(buf)
        out = buf.data
    else
        out = buf[1 : buf.index - 1, :]
    end
    flip ? reverse(out, dims=1) : out
end

mode(buf::Buffer) = buf.mode

snapshot(buf::Buffer) = buf.data

##### Calling Buffers.
(buf::Buffer)() = read(buf)
