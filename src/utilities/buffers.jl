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

    Buffer{M}(data::AbstractVecOrMat{T}) where {M, T<:Real}

Constructs a `Buffer` with `data`.

# Example 
```jldoctest 
julia> buf = Buffer(5)
Buffer(mode:Cyclic, eltype:Float64, size:(5,), index:1, state:empty)

julia> buf = Buffer{Cyclic}(2, 5)
Buffer(mode:Cyclic, eltype:Float64, size:(2, 5), index:1, state:empty)

julia> buf = Buffer{Cyclic}(collect(reshape(1:8, 2, 4)))
Buffer(mode:Cyclic, eltype:Int64, size:(2, 4), index:1, state:empty)
```
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

# Example
```jldoctest
julia> buf = Buffer(2, 5);  # Construct a buffer.

julia> write!(buf, reshape(2 : 2 : 20, 2, 5))  # Write data into buffer.

julia> buf[1]
2.0

julia> buf[1, 2]
6.0

julia> buf[1, end]
18.0

julia> buf[:, 2]
2-element Array{Float64,1}:
 6.0
 8.0
```
"""
getindex(buf::Buffer, idx::Vararg{Int, N}) where N = buf.data[idx...]

"""
    setindex!(buf::Buffer, val, idx)

Sets `val` to `buf` at index `idx`. Same as `buf[idx] = val`.

# Example
```jldoctest
julia> buf = Buffer(2, 5);

julia> buf[1] = 1
1

julia> buf[:, 2] = [1, 1]
2-element Array{Int64,1}:
 1
 1

julia> buf[end] = 10
10

julia> buf.data
2×5 Array{Float64,2}:
 1.0  1.0  0.0  0.0   0.0
 0.0  1.0  0.0  0.0  10.0
```
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

# Example
```jldoctest
julia> buf = Buffer(5)
Buffer(mode:Cyclic, eltype:Float64, size:(5,), index:1, state:empty)

julia> write!(buf, 1.)
1.0

julia> write!(buf, [2, 3])

julia> buf.data
5-element Array{Float64,1}:
 1.0
 2.0
 3.0
 0.0
 0.0

julia> buf = Buffer(2,5)
Buffer(mode:Cyclic, eltype:Float64, size:(2, 5), index:1, state:empty)

julia> write!(buf, [1, 1])
2-element Array{Int64,1}:
 1
 1

julia> write!(buf, [2 3; 2 3])

julia> buf.data
2×5 Array{Float64,2}:
 1.0  2.0  3.0  0.0  0.0
 1.0  2.0  3.0  0.0  0.0
```
"""
write!(buf::Buffer{M, <:Real, 1}, val::Real) where {M} = _write!(buf, val)
write!(buf::Buffer{M, <:Real, 2}, val::AbstractVector{<:Real}) where {M} = _write!(buf, val)
write!(buf::Buffer{M, <:Real, 1}, vals::AbstractVector{<:Real}) where {M} = foreach(val -> _write!(buf, val), vals)
write!(buf::Buffer{M, <:Real, 2}, vals::AbstractMatrix{<:Real}) where {M} = foreach(val -> _write!(buf, val), eachcol(vals))
function _write!(buf::Buffer, val)
    checkstate(buf)
    writeitem(buf, val)
    buf.callbacks(buf)
    val
end
writeitem(buf::Buffer{M, T, 1}, val) where {M, T} = (buf[buf.index] = val; buf.index += 1)
writeitem(buf::Buffer{M, T, 2}, val) where {M, T} = (buf[:, buf.index] = val; buf.index += 1)
checkstate(buf::Buffer) = mode(buf) != Cyclic && isfull(buf) && error("Buffer is full")

"""
    fill!(buf::Buffer, val)

Writes `val` to `buf` until `bus` is full.

# Example
```jldoctest
julia> buf = Buffer(3);

julia> fill!(buf, 1.)
Buffer(mode:Cyclic, eltype:Float64, size:(3,), index:1, state:full)

julia> buf.data
3-element Array{Float64,1}:
 1.0
 1.0
 1.0
```
"""
fill!(buf::Buffer, val) = (foreach(i -> write!(buf, val), 1 : datalength(buf)); buf)

##### Reading from buffers
"""
    read(buf::Buffer)

Reads an element from `buf`. Reading is performed according to the mode of `buf`. See also: [`Normal`](@ref), [`Cyclic`](@ref), [`Lifo`](@ref), [`Fifo`](@ref) for buffer modes. 

# Example
```jldoctest
julia> buf = Buffer(3)
Buffer(mode:Cyclic, eltype:Float64, size:(3,), index:1, state:empty)

julia> write!(buf, [2, 4, 6])

julia> for i = 1 : 3 
       @show (read(buf), buf.data)
       end
(read(buf), buf.data) = (6.0, [2.0, 4.0, 6.0])
(read(buf), buf.data) = (6.0, [2.0, 4.0, 6.0])
(read(buf), buf.data) = (6.0, [2.0, 4.0, 6.0])

julia> buf = Buffer{Fifo}(5)
Buffer(mode:Fifo, eltype:Float64, size:(5,), index:1, state:empty)

julia> write!(buf, [2, 4, 6])

julia> for i = 1 : 3 
       @show (read(buf), buf.data)
       end
(read(buf), buf.data) = (2.0, [4.0, 6.0, 0.0, 0.0, 0.0])
(read(buf), buf.data) = (4.0, [6.0, 0.0, 0.0, 0.0, 0.0])
(read(buf), buf.data) = (6.0, [0.0, 0.0, 0.0, 0.0, 0.0])
```
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

Returns the current data of `buf`. If `flip` is `true`, the data to be returned is flipped. See also [`snapshot`](@ref)

# Example
```jldoctest
julia> buf = Buffer(5);

julia> write!(buf, 1:3)

julia> content(buf, flip=false)
3-element Array{Float64,1}:
 1.0
 2.0
 3.0

julia> buf = Buffer(2, 5);

julia> write!(buf, reshape(1:10, 2, 5))

julia> content(buf)
2×5 Array{Float64,2}:
  9.0  7.0  5.0  3.0  1.0
 10.0  8.0  6.0  4.0  2.0
```
"""
function content(buf::Buffer; flip::Bool=true)
    bufdim = ndims(buf)
    if isfull(buf)
        val = buf.data
    else
        val = bufdim == 1 ? buf[1 : buf.index - 1] : buf[:, 1 : buf.index - 1]
    end
    if flip 
        return bufdim == 1 ? reverse(val, dims=1) : reverse(val, dims=2)
    else
        return val
    end
end

"""
    snapshot(buf::Buffer)

Returns all elements in `buf`. See also: [`content`](@ref)
"""
snapshot(buf::Buffer) = buf.data
