# This file constains the Buffer for data buffering.


##### Buffer modes
"""
    $TYPEDEF

Abstract type for buffer mode. Subtypes of `BufferMode` is `CyclicMode` and `LinearMode`.
"""
abstract type BufferMode end

"""
    $TYPEDEF

Abstract type of cyclic buffer modes. See [`Cyclic`](@ref)
"""
abstract type CyclicMode <: BufferMode end 

"""
    $TYPEDEF

Abstract type of linear buffer modes. See [`Normal`](@ref), [`Lifo`](@ref), [`Fifo`](@ref)
"""
abstract type LinearMode <: BufferMode end  

"""
    $TYPEDEF

Cyclic buffer mode. The data is written to buffer until the buffer is full. When the buffer is full, new data is written by
overwriting the data available in the buffer starting from the beginning of the buffer. When the buffer is read, the element
written last is returned and the returned element is not deleted from the buffer.
"""
struct Cyclic <: CyclicMode end 

"""
    $TYPEDEF

LinearMode buffer mode. The data is written to buffer until the buffer is full. When it is full, no more data is written to
the buffer. When read, the data written last is returned and the returned data is not deleted from the internal container of
the buffer. 
"""
struct Normal <: LinearMode end

"""
    $TYPEDEF

Lifo (Last-in-first-out) buffer mode. This type of buffer is a *last-in-first-out* buffer. Data is written to the buffer
until the buffer is full. When the buffer is full, no more element can be written into the buffer. When read, the last
element written into buffer is returned. The returned element is deleted from the buffer.
"""
struct Lifo <: LinearMode end 

"""
    $TYPEDEF

Fifo (First-in-last-out) buffer mode. This type of buffer is a *first-in-first-out* buffer. The data is written to the buffer
until the buffer is full. When the buffer is full, no more element can be written into the buffer. When read, the first
element written into the buffer is returned. The returned element is deleted from the buffer. 
"""
struct Fifo <: LinearMode end 


##### Buffer
"""
    $TYPEDEF

Constructs a `Buffer` of size `sz` with element type of `T`. `M` is the mode of the `Buffer` that determines how data is to
read from and written into the `Buffer`.  There exists for different buffer modes: 

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

# Fields 

    $TYPEDFIELDS

# Example 
```jldoctest 
julia> buf = Buffer(5)
5-element Buffer{Cyclic,Float64,1}

julia> buf = Buffer{Fifo}(2, 5)
2×5 Buffer{Fifo,Float64,2}

julia> buf = Buffer{Lifo}(collect(reshape(1:8, 2, 4)))
2×4 Buffer{Lifo,Int64,2}
```
"""
mutable struct Buffer{M<:BufferMode, T, N} <: AbstractArray{T, N}
    "Internal data containers"
    internals::Vector{Array{T, N}}
    "Input containter"
    src::Int 
    "Output container"
    dst::Int
    "Buffer index"
    index::Int 
    "Current state of buffer. May be :full, :empty, :nonempty"
    state::Symbol 
    "Unique identifier"
    id::UUID
    Buffer{M}(data::AbstractVecOrMat{T}) where {M, T<:Real} = 
        new{M, T, ndims(data)}([copy(data), data], 1, 2, 1, :empty, uuid4())
end
Buffer{M}(dtype::Type{T}, sz::Int...) where {M, T} = Buffer{M}(zeros(T, sz...)) 
Buffer{M}(sz::Int...) where {M, T} = Buffer{M}(zeros(Float64, sz...)) 
Buffer(dtype::Type{T}, sz::Int...) where T  = Buffer{Cyclic}(dtype, sz...)
Buffer(sz::Int...) = Buffer(Float64, sz...)

show(io::IO, buf::Buffer)= print(io, 
    "Buffer(mode:$(mode(buf)), eltype:$(eltype(buf)), size:$(size(buf)), index:$(buf.index), state:$(buf.state))")

function swapinternals(buf::Buffer) 
    temp = buf.src 
    buf.src = buf.dst 
    buf.dst = temp
end

"""
    $SIGNATURES

Returns the element of `internals` of `buf` that is used to input data to `buf`. See also [`outbuf`][@ref)
"""
inbuf(buf::Buffer) = buf.internals[buf.src]

"""
    $SIGNATURES

Returns the element of `intervals` of `buf` that is used to take data out of `buf`. See also: [`inbuf`](@ref)
"""
outbuf(buf::Buffer) = buf.internals[buf.dst]

##### Buffer info.
"""
    $SIGNATURES

Returns buffer mode of `buf`. See also: [`Normal`](@ref), [`Cyclic`](@ref), [`Lifo`](@ref), [`Fifo`](@ref) for buffer modes. 
"""
mode(buf::Buffer{M, T, N}) where {M, T, N} = M

##### AbstractArray interface.
"""
    $SIGNATURES

Returns the maximum number of data that can be hold in `buf`.

# Example
```jldoctest
julia> buf = Buffer(5);

julia> datalength(buf)
5

julia> buf2 = Buffer(2, 10);

julia> datalength(buf2)
10
```
"""
datalength(buf::Buffer{M, T, N}) where {M, T, N} = N == 1 ? size(buf, 1) : size(buf, 2)

"""
    $SIGNATURES

Returns the size of `buf`.
"""
size(buf::Buffer) = size(outbuf(buf))

"""
    $SIGNATURES

Returns an element from `buf` at index `idx`. Same as `buf[idx]`

# Example
```jldoctest
julia> buf = Buffer(2, 5);  # Construct a buffer.

julia> write!(buf, reshape(2 : 2 : 20, 2, 5))  # Write data into buffer.

julia> buf[1]
18.0

julia> buf[1, 2]
14.0

julia> buf[1, end]
2.0

julia> buf[:, 2]
2-element Array{Float64,1}:
 14.0
 16.0
```
"""
getindex(buf::Buffer, idx::Vararg{Int, N}) where N = getindex(outbuf(buf), idx...)

"""
    $SIGNATURES

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

julia> buf.internals
2-element Array{Array{Float64,2},1}:
 [1.0 1.0 … 0.0 0.0; 0.0 1.0 … 0.0 10.0]
 [0.0 0.0 … 0.0 0.0; 0.0 0.0 … 0.0 0.0]
```
"""
setindex!(buf::Buffer, item, idx::Vararg{Int, N}) where N = setindex!(inbuf(buf), item, idx...)

##### Buffer state control and check.
"""
    $SIGNATURES

Returns `true` if the index of `buf` is 1.
"""
isempty(buf::Buffer) = buf.state == :empty

"""
    $SIGNATURES

Returns `true` if the index of `buf` is equal to the length of `buf`.
"""
isfull(buf::Buffer) = buf.state == :full

"""
    $SIGNATURES

Returns true when `buf` index is an integer multiple of datalength of `buf`. 

# Example
```jldoctest
julia> buf = Buffer(3);

julia> for val in 1 : 7
       write!(buf, val)
       @show ishit(buf)
       end
ishit(buf) = false
ishit(buf) = false
ishit(buf) = true
ishit(buf) = false
ishit(buf) = false
ishit(buf) = true
ishit(buf) = false
```
"""
ishit(buf::Buffer) = buf.state == :full

#
# `setproperty!` function is used to keep track of buffer status. The tracking is done through the updates of `index` of
# buffer. 
#
function setproperty!(buf::Buffer, name::Symbol, val::Int)
    if name == :index
        buflen = datalength(buf)
        val < 1 && error("Buffer index cannot be less than 1.")
        setfield!(buf, name, val)
        if val == 1
            buf.state = :empty
        elseif val > buflen
            buf.state = :full
            if mode(buf) == Cyclic 
                newidx = buflen == 1 ? 1 : (buf.index % buflen)
                setfield!(buf, :index, newidx)
            end 
        else
            buf.state = :nonempty
        end
    else 
        setfield!(buf, name, val)
    end
end

##### Writing into buffers
"""
    $SIGNATURES

Writes each column of `vals` into `buf`.

!!! warning Buffer mode determines how data is written into buffers. See also: [`Normal`](@ref), [`Cyclic`](@ref),
    [`Lifo`](@ref), [`Fifo`](@ref) for buffer modes. 

# Example
```jldoctest
julia> buf = Buffer(5)
5-element Buffer{Cyclic,Float64,1}

julia> write!(buf, 1.)
1.0

julia> write!(buf, [2, 3])

julia> buf.internals
2-element Array{Array{Float64,1},1}:
 [3.0, 2.0, 1.0, 0.0, 0.0]
 [2.0, 1.0, 0.0, 0.0, 0.0]

julia> buf = Buffer(2,5)
2×5 Buffer{Cyclic,Float64,2}

julia> write!(buf, [1, 1])
2-element Array{Int64,1}:
 1
 1

julia> write!(buf, [2 3; 2 3])

julia> buf.internals
2-element Array{Array{Float64,2},1}:
 [3.0 2.0 … 0.0 0.0; 3.0 2.0 … 0.0 0.0]
 [2.0 1.0 … 0.0 0.0; 2.0 1.0 … 0.0 0.0]
```
"""
function write!(buf::Buffer, val) end 
write!(buf::Buffer{M, <:Real, 1}, val::Real) where {M} = _write!(buf, val)
write!(buf::Buffer{M, <:Real, 2}, val::AbstractVector{<:Real}) where {M} = _write!(buf, val)
write!(buf::Buffer{M, <:Real, 1}, vals::AbstractVector{<:Real}) where {M} = foreach(val -> _write!(buf, val), vals)
write!(buf::Buffer{M, <:Real, 2}, vals::AbstractMatrix{<:Real}) where {M} = foreach(val -> _write!(buf, val), eachcol(vals))
function _write!(buf::Buffer, val)
    checkstate(buf)
    ibuf = inbuf(buf)
    obuf = outbuf(buf)
    rotate(ibuf, obuf, 1)
    writeitem(ibuf, val)
    buf.index += 1
    swapinternals(buf)
    val
end
# writeitem(buf::Buffer{M, T, 1}, val) where {M, T} = (buf[buf.index] = val; buf.index += 1)
writeitem(buf::AbstractArray{T, 1}, val) where {T} = buf[1] = val 
writeitem(buf::AbstractArray{T, 2}, val) where {T} = buf[:, 1] = val
checkstate(buf::Buffer) = mode(buf) != Cyclic && isfull(buf) && error("Buffer is full")

##### Reading from buffers
"""
    $SIGNATURES

Reads an element from `buf`. Reading is performed according to the mode of `buf`. See also: [`Normal`](@ref),
[`Cyclic`](@ref), [`Lifo`](@ref), [`Fifo`](@ref) for buffer modes. 

# Example
```jldoctest
julia> buf = Buffer(3)
3-element Buffer{Cyclic,Float64,1}

julia> write!(buf, [2, 4, 6])

julia> for i = 1 : 3 
       @show (read(buf), buf.internals)
       end
(read(buf), buf.internals) = (6.0, [[6.0, 4.0, 2.0], [4.0, 2.0, 0.0]])
(read(buf), buf.internals) = (6.0, [[6.0, 4.0, 2.0], [4.0, 2.0, 0.0]])
(read(buf), buf.internals) = (6.0, [[6.0, 4.0, 2.0], [4.0, 2.0, 0.0]])

julia> buf = Buffer{Fifo}(5)
5-element Buffer{Fifo,Float64,1}

julia> write!(buf, [2, 4, 6])

julia> for i = 1 : 3 
       @show (read(buf), buf.internals)
       end
(read(buf), buf.internals) = (2.0, [[6.0, 4.0, 0.0, 0.0, 0.0], [4.0, 2.0, 0.0, 0.0, 0.0]])
(read(buf), buf.internals) = (4.0, [[6.0, 0.0, 0.0, 0.0, 0.0], [4.0, 2.0, 0.0, 0.0, 0.0]])
(read(buf), buf.internals) = (6.0, [[0.0, 0.0, 0.0, 0.0, 0.0], [4.0, 2.0, 0.0, 0.0, 0.0]])
```
"""
function read(buf::Buffer)
    isempty(buf) && error("Buffer is empty.")
    val = _read(buf)
    val
end
function _read(buf::Buffer{Fifo, T, N}) where {T, N}
    obuf = outbuf(buf)
    val = readitem(obuf, buf.index - 1)
    buf.index -= 1
    insertzero(obuf, buf.index)
    val
end
function _read(buf::Buffer{Lifo, T, N}) where {T, N}
    obuf = outbuf(buf)
    ibuf = inbuf(buf)
    val = readitem(obuf, 1)
    rotate(ibuf, obuf, -1)
    buf.index -= 1
    swapinternals(buf)
    val
end
function _read(buf::Buffer{M, T, N}) where {M<:Union{Normal, Cyclic}, T, N}
    readitem(outbuf(buf), 1)
end
readitem(buf::AbstractArray{T, 1}, idx::Int) where {T} = buf[idx]
readitem(buf::AbstractArray{T, 2}, idx::Int) where {T} = buf[:, idx]
insertzero(buf::AbstractArray{T, 1}, idx::Int) where {T} = buf[idx] = zero(T)
insertzero(buf::AbstractArray{T, 2}, idx::Int) where {T} = buf[:, idx] = zeros(T, size(buf, 1))
rotate(ibuf::AbstractArray{T, 1}, obuf::AbstractArray{T, 1}, idx::Int) where {T} = circshift!(ibuf, obuf, idx)
rotate(ibuf::AbstractArray{T, 2}, obuf::AbstractArray{T, 2}, idx::Int) where {T} = circshift!(ibuf, obuf, (0, idx))

##### Accessing buffer internals
"""
    $SIGNATURES

Returns the current data of `buf`. If `flip` is `true`, the data to be returned is flipped. See also [`snapshot`](@ref)

# Example
```jldoctest
julia> buf = Buffer(5);

julia> write!(buf, 1:3)

julia> content(buf, flip=false)
3-element Array{Float64,1}:
 3.0
 2.0
 1.0

julia> buf = Buffer(2, 5);

julia> write!(buf, reshape(1:10, 2, 5))

julia> content(buf)
2×5 Array{Float64,2}:
 1.0  3.0  5.0  7.0   9.0
 2.0  4.0  6.0  8.0  10.0
```
"""
function content(buf::Buffer; flip::Bool=true)
    bufdim = ndims(buf)
    if isfull(buf)
        val = outbuf(buf)
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
    $SIGNATURES
    
Returns all elements in `buf`. See also: [`content`](@ref)
"""
snapshot(buf::Buffer) = outbuf(buf)

"""
    $(SIGNATURES)

Cleans the contents of `buf`.
"""
function clean!(buf::Buffer)
    buf.internals[1] .= 0.
    buf.internals[2] .= 0.
    buf.index = 1 
    buf
end
