# This file contains the Bus tool for connecting the tools of DsSimulator

import Base: put!, wait, take!
import Base: size, getindex, setindex!, length, iterate, firstindex, lastindex, close, eltype, similar, display


"""
    Bus{T}([nlinks::Int=1, [ln::Int=64]]) where T

Constructs a `Bus` consisting of `nlinks` links. `ln` is the buffer length and `T` is element type of the links.
"""
struct Bus{L<:Link} <: AbstractVector{L}
    links::Vector{L}
    callbacks::Vector{Callback}
    id::UUID
    Bus(links::AbstractVector{L}) where L<:Link = new{L}(links, Callback[], uuid4())
end
Bus(dtype::Type{T}, nlinks::Int, ln::Int=64) where T = Bus([Link(T, ln) for i = 1 : nlinks])
Bus(nlinks::Int=1, ln::Int=64) = Bus(Float64, nlinks, ln)

show(io::IO, bus::Bus) = print(io, "Bus(nlinks:$(length(bus)), eltype:$(eltype(bus)), ",
    "isreadable:$(isreadable(bus)), iswritable:$(iswritable(bus)))")
display(bus::Bus) = show(bus)

##### AbstractVector interface
"""
    size(bus::Bus)

Retruns size of `bus`.
"""
size(bus::Bus) = size(bus.links)

"""
    getindex(bus::Bus, idx::Vararg{Int, N}) where N 

Returns elements from `bus` at index `idx`.
"""
getindex(bus::Bus, idx::Vararg{Int, N}) where N = bus.links[idx...]

"""
    setindex!(bus::Bus, item, idx::Vararg{Int, N}) where N 

Sets `item` to `bus` at index `idx`.
"""
setindex!(bus::Bus, item, idx::Vararg{Int, N}) where N = bus.links[idx...] = item

##### Reading from and writing into from buses
"""
    take!(bus::Bus)

Takes an element from `bus`. Each link of the `bus` is a read and a vector containing the results is returned.

!!! warning 
    The `bus` must be readable to be read. That is, there must be a runnable tasks bound to links of the `bus` that writes data to `bus`.
"""
function take!(bus::Bus) 
    out = take!.(bus[:])
    bus.callbacks(bus)
    out
end

"""
    put!(bus::Bus, vals)

Puts `vals` to `bus`. Each item in `vals` is putted to the `links` of the `bus`.

!!! warning 
    The `bus` must be writable to be read. That is, there must be a runnable tasks bound to links of the `bus` that reads data from `bus`.
"""
function put!(bus::Bus, vals)
    put!.(bus[:], vals)
    bus.callbacks(bus)
    vals
end

##### Interconnection of busses.
"""
    similar(bus::Bus{L}, nlinks::Int=length(bus), ln::Int=64)

Returns a new bus that is similar to `bus` with the same element type. The number of links in the new bus is `nlinks` and data buffer length is `ln`.
"""
similar(bus::Bus{L}, nlinks::Int=length(bus), ln::Int=64) where {L<:Link{T}} where {T} = Bus(T, nlinks, ln)


"""
    hasslaves(bus:Bus)

Returns `true` is all the links of `bus` has slaves. See also [`hasslaves(link::Link)`](@ref)
"""
hasslaves(bus::Bus) = all(hasslaves.(bus[:]))

"""
   hasmaster(bus::Bus) 

Returns `true` is all the links of `bus` has master. See alsos [`hasmaster(link::Link)`](@ref)
"""
hasmaster(bus::Bus) = all(hasmaster.(bus[:]))

##### Closing bus
"""
    close(bus::Bus)

Closes `bus`. When closed, no more data flow is possible for `bus`. 
"""
close(bus::Bus) = foreach(close, bus)

##### Bus state checks
"""
    isfull(bus::Bus)

Returns `true` when the links of `bus` are full.
"""
isfull(bus::Bus) = all(isfull.(bus[:]))

"""
    isreadable(bus::Bus)

Returns `true` if all the links of `bus` is readable.
"""
isreadable(bus::Bus) = all(isreadable.(bus[:]))

"""
    iswritable(bus::Bus)

Returns `true` if all the links of `bus` is writable.
"""
iswritable(bus::Bus) = all(iswritable.(bus[:]))

# ##### Methods on busses.
# # clean!(bus::Bus) = foreach(link -> clean!(link.buffer), bus.links)

"""
    snapshot(bus::Bus)

Returns all the data in links of `bus`.
"""
function snapshot(bus::Bus)
    if length(bus) == 1 
        return vcat([snapshot(link) for link in bus.links]...)
    end
    return hcat([snapshot(link) for link in bus.links]...)
end
    
##### Launching bus
"""
    launch(bus::Bus)

Launches every link of `bus`. See [`launch(link::Link)`](@ref)
"""
launch(bus::Bus) = launch.(bus[:])

"""
    launch(bus::Bus, valrange::AbstractVector)

Launches every links of `bus` with every item of `valrange`. See [`launch(link:Link, valrange)`(@ref)]
"""
launch(bus::Bus, valrange::AbstractVector) = launch.(bus[:], valrange)
