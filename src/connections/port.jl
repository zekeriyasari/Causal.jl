# This file contains the Bus tool for connecting the tools of DsSimulator


abstract type AbstractPort{P} <: AbstractVector{P} end


struct Outport{P} <: AbstractPort{P}
    pins::Vector{P}
    id::UUID
    Outport(pins::AbstractVector{P}) where {T, P<:Outpin{T}} = new{P}(pins, uuid4())
end
Outport{T}(numpins::Int=1) where T = Outport([Outpin{T}() for i = 1 : numpins]) 
Outport(numpins::Int=1) = Outport{Float64}(numpins)

show(io::IO, outport::Outport) = print(io, "Outport(numpins:$(length(outport)), eltype:$(eltype(outport)))")
display(outport::Outport) = println("Outport(numpins:$(length(outport)), eltype:$(eltype(outport)))")


struct Inport{P} <: AbstractPort{P}
    pins::Vector{P}
    Inport(pins::AbstractVector{P}) where {T, P<:Inpin{T}} = new{P}(pins)
end
Inport{T}(numpins::Int=1) where T = Inport([Inpin{T}() for i = 1 : numpins])
Inport(numpins::Int=1) = Inport{Float64}(numpins)

show(io::IO, inport::Inport) = print(io, "Inport(numpins:$(length(inport)), eltype:$(eltype(inport)))")
display(inport::Inport) = println("Inport(numpins:$(length(inport)), eltype:$(eltype(inport)))")


"""
    datatype(bus::Bus)

Returns the data type of `bus`.
"""
datatype(bus::AbstractPort{<:AbstractPin{T}}) where T = T

##### AbstractVector interface
"""
    size(bus::Bus)

Retruns size of `bus`.
"""
size(port::AbstractPort) = size(port.pins)

"""
    getindex(bus::Bus, idx::Vararg{Int, N}) where N 

Returns elements from `bus` at index `idx`. Same as `bus[idx]`.

# Example
```jldoctest
julia> bus = Bus(3);

julia> bus[1]
Link(state:open, eltype:Float64, hasmaster:false, numslaves:0, isreadable:false, iswritable:false)

julia> bus[end]
Link(state:open, eltype:Float64, hasmaster:false, numslaves:0, isreadable:false, iswritable:false)

julia> bus[:]
3-element Array{Link{Float64},1}:
 Link(state:open, eltype:Float64, hasmaster:false, numslaves:0, isreadable:false, iswritable:false)
 Link(state:open, eltype:Float64, hasmaster:false, numslaves:0, isreadable:false, iswritable:false)
 Link(state:open, eltype:Float64, hasmaster:false, numslaves:0, isreadable:false, iswritable:false)
```
"""
getindex(port::AbstractPort, idx::Vararg{Int, N}) where N = port.pins[idx...]

"""
    setindex!(bus::Bus, item, idx::Vararg{Int, N}) where N 

Sets `item` to `bus` at index `idx`. Same as `bus[idx] = item`.

# Example
```jldoctest
julia> bus = Bus(3);

julia> bus[1] = Link()
Link(state:open, eltype:Float64, hasmaster:false, numslaves:0, isreadable:false, iswritable:false)

julia> bus[end] = Link(5)
Link(state:open, eltype:Float64, hasmaster:false, numslaves:0, isreadable:false, iswritable:false)

julia> bus[1:2] = [Link(), Link()]
2-element Array{Link{Float64},1}:
 Link(state:open, eltype:Float64, hasmaster:false, numslaves:0, isreadable:false, iswritable:false)
 Link(state:open, eltype:Float64, hasmaster:false, numslaves:0, isreadable:false, iswritable:false)
```
"""
setindex!(port::AbstractPort, item, idx::Vararg{Int, N}) where N = port.pins[idx...] = item

##### Reading from and writing into from buses
"""
    take!(bus::Bus)

Takes an element from `bus`. Each link of the `bus` is a read and a vector containing the results is returned.

!!! warning 
    The `bus` must be readable to be read. That is, there must be a runnable tasks bound to links of the `bus` that writes data to `bus`.

# Example 
```jldoctest 
julia> b = Bus()
Bus(nlinks:1, eltype:Link{Float64}, isreadable:false, iswritable:false)

julia> t = @async for val in 1 : 5 
       put!(b, [val])
       end;

julia> take!(b)
1-element Array{Float64,1}:
 1.0

julia> take!(b)
1-element Array{Float64,1}:
 2.0
```
"""
take!(inport::Inport) = take!.(inport[:])

"""
    put!(bus::Bus, vals)

Puts `vals` to `bus`. Each item in `vals` is putted to the `links` of the `bus`.

!!! warning 
    The `bus` must be writable to be read. That is, there must be a runnable tasks bound to links of the `bus` that reads data from `bus`.

# Example
```jldoctest
julia> bus = Bus();

julia> t = @async while true 
       val = take!(bus)
       all(val .=== NaN) && break 
       println("Took " * string(val))
       end;

julia> put!(bus, [1.])
Took [1.0]
1-element Array{Float64,1}:
 1.0

julia> put!(bus, [NaN])
1-element Array{Float64,1}:
 NaN
```
"""
function put!(outport::Outport, vals)
    put!.(outport[:], vals)
    vals
end

##### Interconnection of busses.
"""
    similar(bus::Bus{L}, nlinks::Int=length(bus), ln::Int=64)

Returns a new bus that is similar to `bus` with the same element type. The number of links in the new bus is `nlinks` and data buffer length is `ln`.
"""
similar(outport::Outport{P}, numpins::Int=length(outport)) where {P<:Outpin{T}} where {T} = Outport{T}(numpins)
similar(inport::Inport{P}, numpins::Int=length(inport)) where {P<:Inpin{T}} where {T} = Inport{T}(numpins)

