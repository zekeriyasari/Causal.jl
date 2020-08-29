# This file constains the Buffer for data buffering.

export BufferMode, LinearMode, CyclicMode, Buffer, Normal, Cyclic, Fifo, Lifo, write!, 
    isfull, ishit, content, mode 

##### Buffer modes
"""
    $(TYPEDEF)

Abstract type for buffer mode. Subtypes of `BufferMode` is `CyclicMode` and `LinearMode`.
"""
abstract type BufferMode end

"""
    $(TYPEDEF)

Abstract type of cyclic buffer modes. See [`Cyclic`](@ref)
"""
abstract type CyclicMode <: BufferMode end 

"""
    $(TYPEDEF)

Abstract type of linear buffer modes. See [`Normal`](@ref), [`Lifo`](@ref), [`Fifo`](@ref)
"""
abstract type LinearMode <: BufferMode end  

"""
    $(TYPEDEF)

Cyclic buffer mode. The data is written to buffer until the buffer is full. When the buffer is full, new data is written by overwriting the data available in the buffer starting from the beginning of the buffer. When the buffer is read, the element written last is returned and the returned element is not deleted from the buffer.
"""
struct Cyclic <: CyclicMode end 

"""
    $(TYPEDEF)

LinearMode buffer mode. The data is written to buffer until the buffer is full. When it is full, no more data is written to the buffer. When read, the data written last is returned and the returned data is not deleted from the internal container of the buffer. 
"""
struct Normal <: LinearMode end

"""
    $(TYPEDEF)

Lifo (Last-in-first-out) buffer mode. This type of buffer is a *last-in-first-out* buffer. Data is written to the buffer until the buffer is full. When the buffer is full, no more element can be written into the buffer. When read, the last element written into buffer is returned. The returned element is deleted from the buffer.
"""
struct Lifo <: LinearMode end 

"""
    $(TYPEDEF)

Fifo (First-in-last-out) buffer mode. This type of buffer is a *first-in-first-out* buffer. The data is written to the buffer until the buffer is full. When the buffer is full, no more element can be written into the buffer. When read, the first element written into the buffer is returned. The returned element is deleted from the buffer. 
"""
struct Fifo <: LinearMode end 

const BufferDataType{T} = Vector{Union{Missing, T}} where T

##### Buffer
"""
    $(TYPEDEF)

Constructs a `Buffer` of size `sz` with element type of `T`. `M` is the mode of the `Buffer` that determines how data is to read from and written into the `Buffer`.  There exists for different buffer modes: 

* `Normal`: See [`Normal`](@ref)

* `Cyclic`: See [`Cyclic`](@ref)

* `Lifo`: See [`Lifo`](@ref)

* `Fifo`: See [`Fifo`](@ref)

The default mode for `Buffer` is `Cyclic` and default element type is `Float64`.

# Fields 

    $(TYPEDFIELDS)

# Example 
```julia 
julia> buf = Buffer(5)
5-element Buffer{Cyclic,Float64,1}

julia> buf = Buffer{Fifo}(2, 5)
2×5 Buffer{Fifo,Float64,2}

julia> buf = Buffer{Lifo}(collect(reshape(1:8, 2, 4)))
2×4 Buffer{Lifo,Int64,2}
```
"""
mutable struct Buffer{M<:BufferMode, T} <: AbstractVector{T}
    input::BufferDataType{T}
    output::BufferDataType{T}
    index::Int 
    state::Symbol 
    id::UUID
    Buffer{M}(::Type{T}, sz::Int) where {M,T} = new{M,T}(fill(missing, sz), fill(missing, sz), 1, :empty, uuid4())
end
Buffer{M}(sz::Int) where M = Buffer{M}(Float64, sz)
Buffer(::Type{T}, sz::Int) where {T,N} = Buffer{Cyclic}(T, sz)
Buffer(sz::Int) = Buffer(Float64, sz)

show(io::IO, buf::Buffer)= print(io, 
    "Buffer(mode:$(mode(buf)), eltype:$(eltype(buf)), size:$(size(buf)), index:$(buf.index), state:$(buf.state))")

##### Buffer info.
"""
    $(SIGNATURES) 

Returns buffer mode of `buf`. See also: [`Normal`](@ref), [`Cyclic`](@ref), [`Lifo`](@ref), [`Fifo`](@ref) for buffer modes. 
"""
mode(buf::Buffer{M, T}) where {M, T} = M

"""
    $(SIGNATURES) 

Swaps `input` and `output` of `buffer`.
"""
function swap!(buf::Buffer)
    hold = buf.output 
    buf.output = buf.input 
    buf.input = hold 
end

##### AbstractArray interface.
"""
    $(SIGNATURES) 

Returns the size of `buf`.
"""
size(buf::Buffer) = size(buf.input)

"""
    $(SIGNATURES) 

Returns an element from `buf` at index `idx`. Same as `buf[idx]`

# Example
```julia
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
getindex(buf::Buffer, idx::Vararg{Int, N}) where N = buf.output[idx...]

"""
    $(SIGNATURES) 

Sets `val` to `buf` at index `idx`. Same as `buf[idx] = val`.

# Example
```julia
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
setindex!(buf::Buffer, val, idx::Vararg{Int, N}) where N = (buf.input[idx...] = val)

##### Buffer state control and check.
"""
    $(SIGNATURES) 

Returns `true` if the index of `buf` is 1.
"""
isempty(buf::Buffer) = buf.state == :empty

"""
    $SIGNATURES)

Returns `true` if the index of `buf` is equal to the length of `buf`.
"""
isfull(buf::Buffer) = buf.state == :full 

"""
    $(SIGNATURES) 

Returns true when `buf` index is an integer multiple of datalength of `buf`. 

# Example
```julia
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
ishit(buf::Buffer) = buf.index % length(buf) == 1

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
        elseif val > length(buf)
            buf.state = :full
        else
            buf.state = :nonempty
        end
    else 
        setfield!(buf, name, val)
    end
end

##### Writing into buffers
"""
    $(SIGNATURES) 

Writes `val` into `buf`.

!!! warning
    Buffer mode determines how data is written into buffers. See also: [`Normal`](@ref), [`Cyclic`](@ref), [`Lifo`](@ref), [`Fifo`](@ref) for buffer modes. 

# Example
```julia
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
function write!(buf::Buffer, val)
    checkstate(buf)
    circshift!(buf.input, buf.output, 1)
    buf.input[1] = val 
    swap!(buf) 
    buf.index += 1
    val
end
checkstate(buf::Buffer) = mode(buf) != Cyclic && isfull(buf) && error("Buffer is full")

##### Reading from buffers
"""
    $(SIGNATURES) 

Reads an element from `buf`. Reading is performed according to the mode of `buf`. See also: [`Normal`](@ref), [`Cyclic`](@ref), [`Lifo`](@ref), [`Fifo`](@ref) for buffer modes. 

# Example
```julia
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
read(buf::Buffer) = isempty(buf) ? error("Buffer is empty") : _read(buf)
_read(buf::Buffer{Cyclic,T}) where T = buf[1] 
_read(buf::Buffer{Normal,T}) where T = buf[1] 
function _read(buf::Buffer{Fifo, T}) where T
    buf.index -= 1
    val = buf[buf.index] 
    buf.output[buf.index] = missing
    val
end
function _read(buf::Buffer{Lifo, T}) where T 
    val = buf[1]
    buf.output[1] = missing 
    circshift!(buf.input, buf.output, -1)
    swap!(buf)
    buf.index -= 1  
    val
end

# ##### Accessing buffer internals
# """
#     content(buf, [flip=true])

# Returns the current data of `buf`. If `flip` is `true`, the data to be returned is flipped. See also [`snapshot`](@ref)

# # Example
# ```julia
# julia> buf = Buffer(5);

# julia> write!(buf, 1:3)

# julia> content(buf, flip=false)
# 3-element Array{Float64,1}:
#  3.0
#  2.0
#  1.0

# julia> buf = Buffer(2, 5);

# julia> write!(buf, reshape(1:10, 2, 5))

# julia> content(buf)
# 2×5 Array{Float64,2}:
#  1.0  3.0  5.0  7.0   9.0
#  2.0  4.0  6.0  8.0  10.0
# ```
# """
# function content(buf::Buffer; flip::Bool=true)
#     bufdim = ndims(buf)
#     if isfull(buf)
#         val = outbuf(buf)
#     else
#         val = bufdim == 1 ? buf[1 : buf.index - 1] : buf[:, 1 : buf.index - 1]
#     end
#     if flip 
#         return bufdim == 1 ? reverse(val, dims=1) : reverse(val, dims=2)
#     else
#         return val
#     end
# end

# """
#     snapshot(buf::Buffer)

# Returns all elements in `buf`. See also: [`content`](@ref)
# """
# snapshot(buf::Buffer) = outbuf(buf)
