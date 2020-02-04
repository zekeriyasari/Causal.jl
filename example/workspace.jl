import Base: size, getindex, setindex!, setproperty!, show, eltype, length, display, read

struct Cyclic end 
struct Normal end 
struct Lifo end 
struct Fifo end 

mutable struct Buffer{M, T, N} <: AbstractArray{T, N}
    data::Array{T, N}
    index::Int
    state::Symbol
    Buffer{M}(data::AbstractVecOrMat{T}) where {M, T<:Real} = new{M, T, ndims(data)}(data, 1, :empty)
end
Buffer{M}(dtype::Type{T}, sz::Int...) where {M, T} = Buffer{M}(zeros(T, sz...)) 
Buffer{M}(sz::Int...) where {M, T} = Buffer{M}(zeros(Float64, sz...)) 
Buffer(dtype::Type{T}, sz::Int...) where T  = Buffer{Cyclic}(dtype, sz...)
Buffer(sz::Int...) = Buffer(Float64, sz...)

show(io::IO, buf::Buffer)= print(io, 
    "Buffer(mode:$(mode(buf)), eltype:$(eltype(buf)), length:$(length(buf)), index:$(buf.index), state:$(buf.state))")
display(buf::Buffer) = show(buf)

mode(buf::Buffer{M, T, N}) where {M, T, N} = M


size(buf::Buffer) = size(buf.data)
getindex(buf::Buffer, idx::Vararg{Int, N}) where N = buf.data[idx...]
setindex!(buf::Buffer, item, idx::Vararg{Int, N}) where N = buf.data[idx...] = item

function setproperty!(buf::Buffer, name::Symbol, val::Int)
    if name == :index
        val < 1 && error("Buffer index cannot be less than 1.")
        setfield!(buf, name, val)
        if val == 1
            buf.state = :empty
        elseif val > size(buf.data, 1)
            buf.state = :full
            mode(buf) == Cyclic && setfield!(buf, :index, %(buf.index, length(buf)))
        else
            buf.state = :nonempty
        end
    end
end

isfull(buf::Buffer) = buf.state == :full
isempty(buf::Buffer) = buf.state == :empty

function write!(buf::Buffer, val)
    checkstate(buf)
    writeitem(buf, val)
    val
end
writeitem(buf::AbstractVector, val) = (buf[buf.index] = val; buf.index += 1)
writeitem(buf::AbstractMatrix, val) = (buf[buf.index, :] = val; buf.index += 1)
checkstate(buf::Buffer) = mode(buf) != Cyclic && isfull(buf) && error("Buffer is full")

function read(buf::Buffer)
    isempty(buf) && error("Buffer is empty.")
    val = _read(buf)
    val
end
function _read(buf::Buffer{Fifo, T, N}) where {T, N}
    val = readitem(buf, 1)
    buf .= circshift(buf, -1)
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
function _read(buf::Buffer{<:Union{Cyclic, Normal}, T, N}) where {T, N}
    isfull(buf) ? readitem(buf, 1) : readitem(buf, buf.index - 1)
end
readitem(buf::AbstractVector, idx::Int) = buf[idx]
readitem(buf::AbstractMatrix, idx::Int) = buf[idx, :]
