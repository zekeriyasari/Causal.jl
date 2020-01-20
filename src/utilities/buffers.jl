# This file constains the Buffer for data buffering.

import Base: getindex, setindex!, size, read, isempty, setproperty!, fill!, length, eltype, firstindex, lastindex, IndexStyle

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
    Buffer{M}(::Type{T}, ln::Int) where {M, T} 

Constructs a `Buffer` of length `ln` with element type of `T`. `M` is the mode of the `Buffer` that determines how data is to read from and written into the `Buffer`.  There exists for different buffer modes: 

* `Normal`: See [`Normal`](@ref)

* `Cyclic`: See [`Cyclic`](@ref)

* `Lifo`: See [`Lifo`](@ref)

* `Fifo`: See [`Fifo`](@ref)

The default mode for `Buffer` is `Cyclic` and default element type is `Float64`.

    Buffer(::Type{T}, ln::Int) where T 

Constructs a `Buffer` of length `ln` and with element type of `T`. The mode of the buffer is `Cyclic`.

    Buffer{M}(ln::Int) where M

Constructs a `Buffer` of length of `ln` and with mode `M`. `M` can be `Normal`, `Cyclic`, `Fifo` and `Lifo`. The element type of the `Buffer` is `Float64`.

    Buffer(ln::Int) 

Constructs a `Buffer` of length `ln` with mode `Cyclic` and element type of `Float64`.
"""
mutable struct Buffer{M<:BufferMode, T}
    data::Vector{T}
    index::Int 
    state::Symbol 
    callbacks::Vector{Callback}
    id::UUID
    Buffer{M}(::Type{T}, ln::Int) where {M, T} = new{M, T}(Vector{T}(undef, ln), 1, :empty, Callback[], uuid4())
end
Buffer(::Type{T}, ln::Int) where T = Buffer{Cyclic}(T, ln)
Buffer{M}(ln::Int) where M = Buffer{M}(Float64, ln)
Buffer(ln::Int) = Buffer(Float64, ln)

show(io::IO, buf::Buffer)= print(io, 
    "Buffer(mode:$(mode(buf)), eltype:$(eltype(buf)), length:$(length(buf)), index:$(buf.index), state:$(buf.state))")


##### Buffer info.
"""
    mode(buf::Buffer)

Returns buffer mode of `buf`. See also: [`Normal`](@ref), [`Cyclic`](@ref), [`Lifo`](@ref), [`Fifo`](@ref) for buffer modes. 
"""
mode(buf::Buffer{M, T}) where {M, T} = M

"""
    eltype(buf::Buffer)

Returns element type of `buf`.
"""
eltype(buf::Buffer{M, T}) where {M, T} = T

##### AbstractArray interface.
#
# `Buffer` type has linear index style. That means, it can only be indexed by single index. 
# For more information, see (https://docs.julialang.org/en/v1/manual/interfaces/#man-interface-array-1) 
#
IndexStyle(::Type{<:Buffer}) = IndexLinear()

"""
    length(buf::Buffer)

Returns maximum number of elements that can be hold in `buf`.
"""
length(buf::Buffer) = length(buf.data)
size(buf::Buffer) = size(buf.data)

"""
    getindex(buf::Buffer, idx)

Returns an element from `buf` at index `idx`. Same as `buf[idx]`

# Example
```jldoctest
julia> buf = fill!(Buffer(5), 1:5)
Buffer(mode:Cyclic, eltype:Float64, length:5, index:1, state:full)

julia> buf[1]
1.0

julia> buf[2:3]
2-element Array{Float64,1}:
 2.0
 3.0

julia> buf[[3, 5]]
2-element Array{Float64,1}:
 3.0
 5.0

julia> buf[end]
5.0
```
"""
getindex(buf::Buffer, idx::Int) where N = buf.data[idx]
getindex(buf::Buffer, idx::UnitRange) = buf.data[idx]
getindex(buf::Buffer, idx::Vector{Int}) =  buf.data[idx]
getindex(buf::Buffer, idx::UnitRange{Int}) = buf.data[idx]
getindex(buf::Buffer, ::Colon) = buf.data[:]

"""
    setindex!(buf::Buffer, val, idx)

Sets `val` to `buf` at index `idx`. Same as `buf[idx] = val`.

# Example
```jldoctest
julia> buf = Buffer(5)
Buffer(mode:Cyclic, eltype:Float64, length:5, index:1, state:empty)

julia> buf[1] = 1
1

julia> buf[2:3] = 4:5
4:5

julia> buf[[4, 5]] = [10, 20]
2-element Array{Int64,1}:
 10
 20

julia> buf.data
5-element Array{Float64,1}:
  1.0
  4.0
  5.0
 10.0
 20.0
```
"""
setindex!(buf::Buffer, val, inds::Int) where N = (buf.data[inds] = val)
setindex!(buf::Buffer, val, idx::Vector{Int}) = buf.data[idx] = val
setindex!(buf::Buffer, val, idx::UnitRange{Int}) = buf.data[idx] = val
setindex!(buf::Buffer, val, ::Colon) = buf.data[:] = val

firstindex(buf::Buffer) = 1
lastindex(buf::Buffer) = length(buf)  # For indexing like bus[end]

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
        elseif val > size(buf.data, 1)
            buf.state = :full
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
julia> buf = Buffer(Vector{Float64}, 3)
Buffer(mode:Cyclic, eltype:Array{Float64,1}, length:3, index:1, state:empty)

julia> buf.data
3-element Array{Array{Float64,1},1}:
 #undef
 #undef
 #undef

julia> write!(buf, ones(4))
4-element Array{Float64,1}:
 1.0
 1.0
 1.0
 1.0

julia> buf.data
3-element Array{Array{Float64,1},1}:
    [1.0, 1.0, 1.0, 1.0]
 #undef                 
 #undef                 
```
"""
function write!(buf::Buffer, val)
    _write!(buf, val)
    buf.callbacks(buf)
    val
end
function _write!(buf::Buffer{M, T}, val) where {M <: LinearMode, T}
    if isfull(buf) 
        @warn "Buffer is full."
    else 
        buf[buf.index] = val 
        buf.index +=1
    end
end
function _write!(buf::Buffer{M, T}, val) where {M <: CyclicMode, T}
    buf[buf.index] = val
    buf.index += 1
    if isfull(buf)
        setfield!(buf, :index, %(buf.index, length(buf)))
    end
end

"""
    fill!(buf::Buffer{M, T}, val::T)

Writes `val` into `buf` until `buf` is full. If `val` is a vector

    fill!(buf::Buffer{M, T}, val::AbstractVector{T}) where {M, T}

Writes all items in `val` into `buf`. 

# Example 
```jldoctest
julia> buf = Buffer(3)
Buffer(mode:Cyclic, eltype:Float64, length:3, index:1, state:empty)

julia> fill!(buf, 1.)
Buffer(mode:Cyclic, eltype:Float64, length:3, index:1, state:full)

julia> all(buf.data .== ones(3))
true

julia> buf = Buffer(3)
Buffer(mode:Cyclic, eltype:Float64, length:3, index:1, state:empty)

julia> fill!(buf, 1:3)
Buffer(mode:Cyclic, eltype:Float64, length:3, index:1, state:full)

julia> all(buf.data .== 1. : 3.)
true
```
"""
fill!(buf::Buffer{M, T}, val::T) where {M, T} = (foreach(i -> write!(buf, val), 1 : length(buf)); buf)
fill!(buf::Buffer{M, T}, val::S) where {M, T, S} = fill!(buf, convert(T, val))
fill!(buf::Buffer{M, T}, val::AbstractVector{T}) where {M, T} = (foreach(i -> write!(buf, i), val); buf)
fill!(buf::Buffer{M, T}, val::AbstractVector{S}) where {M, T, S} = fill!(buf, convert(Vector{T}, val))

##### Reading from buffers
"""
    read(buf::Buffer)

Reads an element from `buf`. Reading is performed according to the mode of `buf`. See also: [`Normal`](@ref), [`Cyclic`](@ref), [`Lifo`](@ref), [`Fifo`](@ref) for buffer modes. 

# Example
```jldoctest
julia> buf = fill!(Buffer{Fifo}(3), 1. : 3.)
Buffer(mode:Fifo, eltype:Float64, length:3, index:4, state:full)

julia> for i in 1 : 3 
       @show read(buf)
       end
read(buf) = 1.0
read(buf) = 2.0
read(buf) = 3.0

julia> buf = fill!(Buffer{Lifo}(3), 1. : 3.)
Buffer(mode:Lifo, eltype:Float64, length:3, index:4, state:full)

julia> for i in 1 : 3 
       @show read(buf)
       end
read(buf) = 3.0
read(buf) = 2.0
read(buf) = 1.0

julia> buf = fill!(Buffer{Cyclic}(3), 1. : 3.)
Buffer(mode:Cyclic, eltype:Float64, length:3, index:1, state:full)

julia> for i in 1 : 3 
       @show read(buf)
       end
read(buf) = 3.0
read(buf) = 3.0
read(buf) = 3.0
```
"""
function read(buf::Buffer) 
    isempty(buf) && error("Buffer is empty")
    val = _read(buf)
    buf.callbacks(buf)
    val
end
_read(buf::Buffer{M, T}) where {M<:Union{Normal, Cyclic}, T} = isfull(buf) ? buf[end] :  buf[buf.index - 1]
function _read(buf::Buffer{M, T}) where {M<:Fifo, T}
    val = buf[1]
    buf.data .= circshift(buf.data, -1)
    buf[end] = Vector{T}(undef, 1)[1]
    buf.index -= 1
    val
end
function _read(buf::Buffer{M, T}) where {M<:Lifo, T}
    buf.index -= 1
    val = buf[buf.index]
    buf[buf.index] = Vector{T}(undef, 1)[1]
    val
end

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
