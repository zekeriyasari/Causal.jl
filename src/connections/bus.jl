# This file contains the Bus tool for connecting the tools of DsSimulator

import Base: put!, wait, take!
import Base: size, getindex, setindex!, length, iterate, firstindex, lastindex, close, eltype


struct Bus{T}
    links::Vector{Link{T}}
    callbacks::Vector{Callback}
    id::UUID
    Bus{T}(nlinks::Int=1, ln::Int=64) where T = 
        new{Union{Missing, T}}([Link{T}(ln) for i = 1 : nlinks], Callback[], uuid4())
end
Bus(nlinks::Int=1, ln::Int=64) = Bus{Float64}(nlinks, ln)

show(io::IO, bus::Bus{Union{Missing, T}})  where T = print(io, "Bus(nlinks:$(length(bus)), eltype:$(T), ",
    "isreadable:$(isreadable(bus)), iswritable:$(iswritable(bus)))")

##### Make bus indexable.
eltype(bus::Bus{T}) where {T} = T
length(bus::Bus) = length(bus.links)
size(bus::Bus) = size(bus.links)
getindex(bus::Bus, I::Int) =  bus.links[I]
getindex(bus::Bus, I::Vector{Int}) =  bus.links[I]
getindex(bus::Bus, I::UnitRange{Int}) = bus.links[I]
getindex(bus::Bus, ::Colon) = bus.links[:]
setindex!(bus::Bus, val, I::Int) = bus.links[I] = val
setindex!(bus::Bus, val::AbstractVector, I::Vector{Int}) = bus.links[I] = val
setindex!(bus::Bus, val::AbstractVector, I::UnitRange{Int}) = bus.links[I] = val
setindex!(bus::Bus, val::AbstractVector, ::Colon) = bus.links[:] = val
firstindex(bus::Bus) = 1
lastindex(bus::Bus) = length(bus)  # For indexing like bus[end]

##### Reading from and writing into from buses
function take!(bus::Bus) 
    out = take!.(bus.links)
    bus.callbacks(bus)
    out
end
function put!(bus::Bus, vals)
    put!.(bus.links, vals)
    bus.callbacks(bus)
    vals
end

##### Iterating bus
iterate(bus::Bus, i=1) = i > length(bus.links) ? nothing : (bus.links[i], i + 1)   # When iterated, return links

##### Connecting disconnecting busses.
const LinkOrLinkArrayOrBus = Union{<:Link, <:AbstractVector{<:Link}, <:Bus}
getlinks(bus::Bus) = bus.links
getlinks(linkchunk::AbstractVector{<:Link}) = linkchunk
getlinks(link::Link) = [link]
connect(linkchunk1::LinkOrLinkArrayOrBus, linkchunk2::LinkOrLinkArrayOrBus) = 
    connect(getlinks(linkchunk1), getlinks(linkchunk2))
disconnect(linkchunk1::LinkOrLinkArrayOrBus, linkchunk2::LinkOrLinkArrayOrBus) = 
    disconnect(getlinks(linkchunk1), getlinks(linkchunk2))
insert(linkchunk1::LinkOrLinkArrayOrBus, linkchunk2::LinkOrLinkArrayOrBus, linkchunk3::LinkOrLinkArrayOrBus) = 
    insert(getlinks(linkchunk1), getlinks(linkchunk2), getlinks(linkchunk3))
release(linkchunk::LinkOrLinkArrayOrBus) = foreach(release, getlinks(linkchunk))

##### Interconnection of busses.
hasslaves(bus::Bus) = all(hasslaves.(bus.links))
hasmaster(bus::Bus) = all(hasmaster.(bus.links))

##### Closing bus
close(bus::Bus) = foreach(close, bus)

##### Bus state checks
isfull(bus::Bus) = all(isfull.(bus.links))
isreadable(bus::Bus) = all(isreadable.(bus.links))
iswritable(bus::Bus) = all(iswritable.(bus.links))
isconnected(linkchunk1, linkchunk2) = all(isconnected.(getlinks(linkchunk1), getlinks(linkchunk2)))

##### Methods on busses.
clean!(bus::Bus) = foreach(link -> clean!(link.buffer), bus.links)
snapshot(bus::Bus) = 
    length(bus) == 1 ? vcat([snapshot(link) for link in bus.links]...) : hcat([snapshot(link) for link in bus.links]...)
    
##### Launching bus
launch(bus::Bus) = launch.(bus.links)
launch(bus::Bus, valrange::AbstractVector) = launch.(bus.links, valrange)
