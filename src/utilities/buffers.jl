# This file constains the Buffer for data buffering.

import Base: getindex, setindex!, size, read, isempty, setproperty!, fill!, length, eltype, firstindex, lastindex, IndexStyle, display

##### Buffer modes
"""
    BufferMode 

Abstract type for buffer mode. Subtypes of `BufferMode` is `CyclicMode` and `LinearMode`.
"""
abstract type BufferMode end

"""
    CyclicMode <: BufferMode

Abstract type of cyclic buffer modes. See [`Cyclic`](@ref)
"""
abstract type CyclicMode <: BufferMode end 

"""
    LinearMode <: BufferMode 

Abstract type of linear buffer modes. See [`Normal`](@ref), [`Lifo`](@ref), [`Fifo`](@ref)
"""
abstract type LinearMode <: BufferMode end  

"""
    Cyclic <: CyclicMode

Cyclic buffer mode. The data is written to buffer until the buffer is full. When the buffer is full, new data is written by overwriting the data available in the buffer starting from the beginning of the buffer. When the buffer is read, the element written last is returned and the returned element is not deleted from the buffer.
"""
struct Cyclic <: CyclicMode end 

"""
    Normal <: LinearMode

LinearMode buffer mode. The data is written to buffer until the buffer is full. When it is full, no more data is written to the buffer. When read, the data written last is returned and the returned data is not deleted from the internal container of the buffer. 
"""
struct Normal <: LinearMode end

"""
    Lifo <: LinearMode

Lifo (Last-in-first-out) buffer mode. This type of buffer is a *last-in-first-out* buffer. Data is written to the buffer until the buffer is full. When the buffer is full, no more element can be written into the buffer. When read, the last element written into buffer is returned. The returned element is deleted from the buffer.
"""
struct Lifo <: LinearMode end 

"""
    Fifo <: LinearMode

Fifo (First-in-last-out) buffer mode. This type of buffer is a *first-in-first-out* buffer. The data is written to the buffer until the buffer is full. When the buffer is full, no more element can be written into the buffer. When read, the first element written into the buffer is returned. The returned element is deleted from the buffer. 
"""
struct Fifo <: LinearMode end 


##### Buffer
"""
    Buffer{M}(dtype::Type{T}, sz::Int...) where {M, T}

Constructs a `Buffer` of size `sz` with element type of `T`. `M` is the mode of the `Buffer` that determines how data is to read from and written into the `Buffer`.  There exists for different buffer modes: 

* `Normal`: See [`Normal`](@ref)

* `Cyclic`: See [`Cyclic`](@ref)

* `Lifo`: See [`Lifo`](@ref)

* `Fifo`: See [`Fifo`](@ref)

The default mode for `Buffer` is `Cyclic` and default element type is `Float64`.

    Buffer{M}(sz::Int...) where {M, T}

Constructs a `Buffer` of size `sz` and with element type of `T` and mode `M`.

    Buffer(dtype::Type{T}, sz::Int...) where T

Constructs a `Buffer` of size `sz` and element type `T`. The mode of buffer is `Cyclic`.

    Buffer(sz::Int...)  

Constructs a `Buffer` of size `sz` with mode `Cyclic` and element type of `Float64`.
"""
mutable struct Buffer{M<:BufferMode, T, N} <: AbstractArray{T, N}
    data::Array{T, N}
    index::Int 
    state::Symbol 
    callbacks::Vector{Callback}
    id::UUID
    Buffer{M}(data::AbstractVecOrMat{T}) where {M, T<:Real} = new{M, T, ndims(data)}(data, 1, :empty, Callback[], uuid4())
end
Buffer{M}(dtype::Type{T}, sz::Int...) where {M, T} = Buffer{M}(zeros(T, sz...)) 
Buffer{M}(sz::Int...) where {M, T} = Buffer{M}(zeros(Float64, sz...)) 
Buffer(dtype::Type{T}, sz::Int...) where T  = Buffer{Cyclic}(dtype, sz...)
Buffer(sz::Int...) = Buffer(Float64, sz...)

show(io::IO, buf::Buffer)= print(io, 
    "Buffer(mode:$(mode(buf)), eltype:$(eltype(buf)), size:$(size(buf)), index:$(buf.index), state:$(buf.state))")
display(buf::Buffer) = println( 
    "Buffer(mode:$(mode(buf)), eltype:$(eltype(buf)), size:$(size(buf)), index:$(buf.index), state:$(buf.state))")

##### Buffer info.
"""
    mode(buf::Buffer)

Returns buffer mode of `buf`. See also: [`Normal`](@ref), [`Cyclic`](@ref), [`Lifo`](@ref), [`Fifo`](@ref) for buffer modes. 
"""
mode(buf::Buffer{M, T, N}) where {M, T, N} = M

##### AbstractArray interface.
"""
    datalength(buf::Buffer)

Returns the data length of `buf`.
"""
datalength(buf::Buffer) = isa(buf, AbstractVector) ? size(buf, 1) : size(buf, 2)

"""
    size(buf::Buffer)

Returns the size of `buf`.
"""
size(buf::Buffer) = size(buf.data)

"""
    getindex(buf::Buffer, idx::Vararg{Int, N})

Returns an element from `buf` at index `idx`. Same as `buf[idx]`
```
"""
getindex(buf::Buffer, idx::Vararg{Int, N}) where N = buf.data[idx...]

"""
    setindex!(buf::Buffer, val, idx)

Sets `val` to `buf` at index `idx`. Same as `buf[idx] = val`.
"""
setindex!(buf::Buffer, item, idx::Vararg{Int, N}) where N = buf.data[idx...] = item

##### Buffer state control and check.
"""
    isempty(buf::Buffer)

Returns `true` if the index of `buf` is 1.
"""
isempty(buf::Buffer) = buf.state == :empty

"""
    isfull(buf::Buffer)

Returns `true` if the index of `buf` is equal to the length of `buf`.
"""
isfull(buf::Buffer) = buf.state == :full

#
# `setproperty!` function is used to keep track of buffer status. 
# The tracking is done through the updates of `index` of buffer. 
#
function setproperty!(buf::Buffer, name::Symbol, val::Int)
    if name == :index
        val < 1 && error("Buffer index cannot be less than 1.")
        setfield!(buf, name, val)
        if val == 1
            buf.state = :empty
        elseif val > datalength(buf)
            buf.state = :full
            mode(buf) == Cyclic && setfield!(buf, :index, %(buf.index, datalength(buf)))
        else
            buf.state = :nonempty
        end
    end
end

##### Writing into buffers
"""
    write!(buf::Buffer{M, T}, val) where {M, T}

Writes `val` into `buf`. Writing is carried occurding the mode `M` of `buf`. See also: [`Normal`](@ref), [`Cyclic`](@ref), [`Lifo`](@ref), [`Fifo`](@ref) for buffer modes. 
"""
function write!(buf::Buffer, val)
    checkstate(buf)
    writeitem(buf, val)
    buf.callbacks(buf)
    val
end

write!(buf::Buffer{M, <:Real, 1}, vals::AbstractVector{<:Real}) where {M} = foreach(val -> write!(buf, val), vals)

writeitem(buf::Buffer{M, T, 1}, val) where {M, T} = (buf[buf.index] = val; buf.index += 1)
writeitem(buf::Buffer{M, T, 2}, val) where {M, T} = (buf[:, buf.index] = val; buf.index += 1)
checkstate(buf::Buffer) = mode(buf) != Cyclic && isfull(buf) && error("Buffer is full")

"""
    fill!(buf::Buffer, val)

Writes `val` to `buf` until `bus` is full.
"""
fill!(buf::Buffer, val) = (foreach(i -> write!(buf, val), 1 : datalength(buf)); buf)

##### Reading from buffers
"""
    read(buf::Buffer)

Reads an element from `buf`. Reading is performed according to the mode of `buf`. See also: [`Normal`](@ref), [`Cyclic`](@ref), [`Lifo`](@ref), [`Fifo`](@ref) for buffer modes. 
"""
function read(buf::Buffer)
    isempty(buf) && error("Buffer is empty.")
    val = _read(buf)
    buf.callbacks(buf)
    val
end
function _read(buf::Buffer{Fifo, T, N}) where {T, N}
    val = readitem(buf, 1)
    buf .= rotate(buf)
    buf.index -= 1
    buf[end] = zero(eltype(buf))
    val
end
function _read(buf::Buffer{Lifo, T, N}) where {T, N}
    buf.index -= 1
    val = readitem(buf, buf.index)
    buf[buf.index] = zero(eltype(buf))
    val
end
_read(buf::Buffer{Normal, T, N}) where {T, N} = readitem(buf, buf.index - 1)
_read(buf::Buffer{Cyclic, T, N}) where {T, N} = isfull(buf) ? readitem(buf, datalength(buf)) : readitem(buf, buf.index - 1)
readitem(buf::Buffer{M, T, 1}, idx::Int) where {M, T} = buf[idx]
readitem(buf::Buffer{M, T, 2}, idx::Int) where {M, T} = buf[:, idx]
rotate(buf::Buffer{M, T, 1}) where {M, T} = circshift(buf, -1)
rotate(buf::Buffer{M, T, 2}) where {M, T} = circshift(buf, (0, -1))

##### Accessing buffer data
"""
    content(buf, [flip=true])

Returns the current data of `buf`. If `flip` is `true`, the data to be returned is flipped. 
"""
function content(buf::Buffer; flip::Bool=true)
    val = buf[1 : buf.index - 1]
    flip ? reverse(val, dims=1) : val
end

"""
    snapshot(buf::Buffer)

Returns all elements in `buf`.
"""
snapshot(buf::Buffer) = buf.data
