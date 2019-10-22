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
take!(bus::Bus) = (out = take!.(bus.links); bus.callbacks(bus); out)
put!(bus::Bus, vals)  = (put!.(bus.links, vals); bus.callbacks(bus); vals)

##### Iterating bus
iterate(bus::Bus, i=1) = i > length(bus.links) ? nothing : (bus.links[i], i + 1)

##### Connecting disconnecting busses.
connect(srcbus::Bus, dstbus::Bus) = (connect.(srcbus.links, dstbus.links); return)
connect(bus::Bus, links::Vector{<:Link}) = (connect.(bus.links, links); return)
connect(bus::Bus, link::Link) = (connect.(bus.links, [link]); return)
connect(link::Link, bus::Bus) = (connect.([link], bus.links); return)
connect(links::Vector{<:Link}, bus::Bus) = (connect.(links, bus.links); return)
disconnect(srcbus::Bus, dstbus::Bus) = (disconnect.(srcbus.links, dstbus.links); return)
disconnect(bus::Bus, links::Vector{<:Link}) = (disconnect.(bus.links, links); return)
disconnect(links::Vector{<:Link}, bus::Bus) = (disconnect.(links, bus.links); return)
disconnect(bus::Bus, link::Link) = (disconnect.(bus.links, [link]); return)
disconnect(link::Link, bus::Bus) = (disconnect.([link], bus.links); return)

release(bus::Bus) = foreach(release, bus.links)

##### Interconnection of busses.
hasslaves(bus::Bus) = all(hasslaves.(bus.links))
hasmaster(bus::Bus) = all(hasmaster.(bus.links))

##### Closing bus
close(bus::Bus) = foreach(close, bus)

##### Bus state checks
isfull(bus::Bus) = all(isfull.(bus.links))
isreadable(bus::Bus) = all(isreadable.(bus.links))
iswritable(bus::Bus) = all(iswritable.(bus.links))
isconnected(srcbus::Bus, dstbus::Bus) = all(isconnected.(srcbus.links, dstbus.links))
isconnected(bus::Bus, links::Vector{<:Link}) = all(isconnected.(bus.links, links))
isconnected(bus::Bus, link::Link) = all(isconnected.(bus.links, [link]))
isconnected(link::Link, bus::Bus) = all(isconnected.([link], bus.links))
isconnected(links::Vector{<:Link}, bus::Bus) = all(isconnected.(links, bus.links))

##### Methods on busses.
clean!(bus::Bus) = foreach(link -> clean!(link.buffer), bus.links)
snapshot(bus::Bus) = 
    length(bus) == 1 ? vcat([snapshot(link) for link in bus.links]...) : hcat([snapshot(link) for link in bus.links]...)
    
##### Launching bus
launch(bus::Bus) = launch.(bus.links)
launch(bus::Bus, valrange::AbstractVector) = launch.(bus.links, valrange)
