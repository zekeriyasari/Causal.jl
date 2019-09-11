# This file contains the Bus tool for connecting the tools of DsSimulator

import Base: put!, wait, take!
import Base: size, getindex, setindex!, length, iterate, firstindex, lastindex, close


struct Bus{T} <: AbstractBus{T}
    links::Vector{Link{T}}
    callbacks::Vector{Callback}
    id::UUID
end
Bus{T}(nlinks::Int=1, ln::Int=64) where {T} = Bus([Link{T}(ln) for i = 1 : nlinks], Callback[], uuid4())
Bus(nlinks::Int=1, ln::Int=64) = Bus{Float64}(nlinks, ln)


##### Make bus indexable.
size(bus::Bus) = [size(link.buffer) for link in bus.links]
getindex(bus::Bus, I::Int) =  bus.links[I]
getindex(bus::Bus, I::Vector{Int}) =  bus.links[I]
getindex(bus::Bus, I::UnitRange{Int}) = bus.links[I]
getindex(bus::Bus, ::Colon) = bus.links[:]
setindex!(bus::Bus, val, I::Int) = bus.links[I] = val
setindex!(bus::Bus, val::AbstractVector, I::Vector{Int}) = bus.links[I] = val
setindex!(bus::Bus, val::AbstractVector, I::UnitRange{Int}) = bus.links[I] = val
setindex!(bus::Bus, val::AbstractVector, ::Colon) = bus.links[:] = val
# setindex!(bus::Bus, val, I::Int) where N = (bus.links[I] = val; connect(bus.links[I], val)
# setindex!(bus::Bus, val::AbstractVector, I::Vector{Int}) where N = (bus.links[I] = val; connect.(bus.links[I], val))
# setindex!(bus::Bus, val::AbstractVector, I::UnitRange{Int}) where N = (bus.links[I] = val; connect.(bus.links[I], val))
# setindex!(bus::Bus, val::AbstractVector, ::Colon) = (bus.links[:] = val; connect.(bus.links[:], val))
firstindex(bus::Bus) = 1
lastindex(bus::Bus) = length(bus)  # For indexing like bus[end]

length(bus::Bus) = length(bus.links)

iterate(bus::Bus, i=1) = i > length(bus.links) ? nothing : (bus.links[i], i + 1)

##### Connecting disconnecting busses.
connect(srcbus::Bus, dstbus::Bus) = connect.(srcbus.links, dstbus.links)
connect(bus::Bus, links::Vector{Link}) = connect.(bus.links, links) 
connect(bus::Bus, link::Link) = connect.(bus.links, [link]) 
connect(link::Link, bus::Bus) = connect.([link], bus.links) 
connect(links::Vector{Link}, bus::Bus) = connect.(links, bus.links)
disconnect(srcbus::Bus, dstbus::Bus) = disconnect.(srcbus.links, dstbus.links)
disconnect(bus::Bus, links::Vector{Link}) = disconnect.(bus.links, links) 
disconnect(links::Vector{Link}, bus::Bus) = disconnect.(links, bus.links)
disconnect(bus::Bus, link::Link) = disconnect.(bus.links, [link]) 
disconnect(link::Link, bus::Bus) = disconnect.([link], bus.links) 

##### Interconnection of busses.
hasslaves(bus::Bus) = all(hasslaves.(bus.links))
hasmaster(bus::Bus) = all(hasmaster.(bus.links))

##### Reading from and writing into from buses
function take!(bus::Bus, t)
    # out = [take!(link, t) for link in bus.links]
    out = take!.(bus.links, fill(t, length(bus)))  # Dot convention makes also the size check.
    bus.callbacks(bus)
    out
end

function take!(bus::Bus)
    out = take!.(bus.links)  # Dot syntax makes vectorization.   
    bus.callbacks(bus)
    out
end

function put!(bus::Bus{T}, vals::AbstractVector{T}) where {T} 
    put!.(bus.links, vals)  # Dot syntax also makes the size checks.
    bus.callbacks(bus)
end
put!(bus::Bus{T}, vals::AbstractVector{S}) where {T, S} = put!(bus, convert(Vector{T}, vals))
put!(buf::Bus{T}, val::T) where {T} = put!(bus, [val])
put!(buf::Bus{T}, val::S) where {T, S} = put!(bus, convert(T, val))

close(bus::Bus) = foreach(close, bus)

##### Waiting for busses
wait(bus::Bus) = foreach(link -> wait(link), bus.links)
wait(buses::AbstractVector{B}) where B<:AbstractBus = foreach(bus -> wait(bus), buses)

##### Bus state checks
isfull(bus::Bus) = all(isfull.(bus.links))
isconnected(srcbus::Bus, dstbus::Bus) = all(isconnected.(srcbus.links, dstbus.links))
isconnected(bus::Bus, links::Vector{Link}) = all(isconnected.(bus.links, links))
isconnected(bus::Bus, link::Link) = all(isconnected.(bus.links, [link]))
isconnected(link::Link, bus::Bus) = all(isconnected.([link], bus.links))
isconnected(links::Vector{Link}, bus::Bus) = all(isconnected.(links, bus.links))


##### Calling busses.
(bus::Bus)(t::Real) = take!(bus, t)

##### Methods on busses.
clean!(bus::Bus) = foreach(link -> clean!(link.buffer), bus.links)

snapshot(bus::Bus) = length(bus) == 1 ? vcat([snapshot(link) for link in bus.links]...) : 
    hcat([snapshot(link) for link in bus.links]...)
    
function transfer_data(srcbus::Bus, dstbus::Bus)
    srclinks = srcbus.links
    dstlinks = dstbus.links
    foreach(i -> write!(dstlinks[i].buffer, srclinks[i].buffer.data), 1:length(srcbus))
end

##### Launching bus
launch(bus::AbstractBus, taskname::Symbol, valranges=fill(nothing, length(bus))) =
    launch.(bus.links, fill(taskname, length(bus)), valranges)
