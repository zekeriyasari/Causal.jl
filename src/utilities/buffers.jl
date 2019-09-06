# This file constains the Buffer for data buffering.

import Base: getindex, setindex!, size, read, isempty, fill!, setproperty!, similar

##### Buffer modes
abstract type BufferMode end 
struct Normal <: BufferMode end
struct Cyclic <: BufferMode end 
struct Lifo <: BufferMode end 
struct Fifo <: BufferMode end 

##### Buffer
mutable struct Buffer{M<:BufferMode, T, N} <: AbstractBuffer{T, N}
    data::Array{T,N}
    index::Int 
    state::Symbol       # May be `:empty`, `:nonempty`, `:full`
    callbacks::Vector{Callback}
    id::UUID
end
Buffer{M}(data::Array{T, N}) where {M, T, N} = Buffer{M, T, N}(data, 1, :empty, Callback[], uuid4())
Buffer{M}(::Type{T}, shape::NTuple{N, Int}) where {M, T, N} = Buffer{M}(Array{T,N}(undef, shape...))
Buffer{M}(shape::Int...) where M = Buffer{M}(Float64, shape)
Buffer(shape::Int...) = Buffer{Cyclic}(shape...)

##### AbstractArray interface.
size(buf::Buffer) = size(buf.data)
getindex(buf::Buffer, idx::Vararg{Int, N}) where N = getindex(buf.data[idx...])
setindex!(buf::Buffer, val, inds::Vararg{Int, N}) where N = (buf.data[inds...] = val)

##### Buffer state control and check.
isempty(buf::Buffer) = buf.state == :empty
isfull(buf::Buffer) = buf.state == :full
function setproperty!(buf::Buffer, name::Symbol, val::Int)
    if name == :index
        val < 1 && error("Buffer index cannot be less than 1.")
        setfield!(buf, name, val)
        if val == 1
            buf.state = :empty
        elseif val > size(buf.data, 1)
            buf.state = :full
        else
            buf.state = :nonempty
        end
    end
end

##### Writing into buffers
resetindex(buf::Buffer) = setfield!(buf, :index, %(buf.index, size(buf.data, 1)))
checkindex(buf::Buffer) = isfull(buf) && resetindex(buf)
function _write(buf::Buffer, val::AbstractArray)
    n = size(val, 1)
    buf.data .= circshift(buf.data, n)
    buf.data[1:n, :] = val
    buf.index += n
    buf.callbacks(buf)
    val
end
write!(buf::Buffer, val::AbstractArray) = isfull(buf) ? (@warn "Buffer is full.") : _write(buf, val)
write!(buf::Buffer{Cyclic, T, N}, val::AbstractArray) where {T, N} = (_write(buf, val); checkindex(buf); val)
write!(buf::Buffer, val::Real) = write!(buf, [val]) 
write!(buf::Buffer{M, T, 2}, val::Vector) where {M, T} = write!(buf, hcat(val...))

##### Reading from buffers.
colrange(buf::Buffer) = [(:) for i in 1 : ndims(buf) - 1]
getelement(buf::Buffer, idx::Int) = buf[idx, colrange(buf)...]
setelement(buf::Buffer, idx::Int, val) = (buf[idx, colrange(buf)...] .= val; val)

_read(buf::Buffer{Normal, T, N}) where {T, N} = getelement(buf, 1)
_read(buf::Buffer{Cyclic, T, N}) where {T, N} = getelement(buf, 1)
function _read(buf::Buffer{Fifo, T, N}) where {T, N}
    buf.index -= 1
    val = getelement(buf, buf.index)
    buf[1, colrange(buf)...] .= zero(T)
    val
end
function _read(buf::Buffer{Lifo, T, N}) where {T, N}
    val = getelement(buf, 1)
    buf.data .= circshift(buf, -1)
    buf[end, colrange(buf)...] = zero(T)
    buf.index -= 1
end
read(buf::Buffer) = isempty(buf) ? (@warn "Buffer is empty.") : (val = _read(buf); buf.callbacks(buf); val)

##### Accessing buffer data
function content(buf::Buffer; flip::Bool=true)
    val = buf[1 : buf.index - 1, colrange(buf)...]
    flip ? reverse(val, dims=1) : val
end

snapshot(buf::Buffer) = buf.data

##### Buffer info.
mode(buf::Buffer{M, T, N}) where {M, T, N} = M

##### Calling buffers.
(buf::Buffer)() = read(buf)
