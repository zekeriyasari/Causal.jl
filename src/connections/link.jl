# This file contains the links to connect together the tools of DsSimulator.

import Base: put!, take!, RefValue, close, isready, eltype, isopen


struct Poison end

const PoisonOr{T} = Union{Poison, T}

struct Pin
    id::UUID
end
Pin() = Pin(uuid4())


mutable struct Link{T} <: AbstractLink{T}
    buffer::Buffer{Cyclic, T}
    channel::Channel{PoisonOr{T}}
    leftpin::Pin
    rightpin::Pin
    callbacks::Vector{Callback}
    id::UUID
    master::RefValue{Link{T}}
    slaves::Vector{RefValue{Link{T}}}
end
Link{T}(ln::Int=64) where {T} = Link(Buffer(T, ln), Channel{PoisonOr{T}}(0), Pin(), Pin(), Callback[], uuid4(), RefValue{Link{T}}(), Vector{RefValue{Link{T}}}()) 
Link(ln=64) = Link{Float64}(ln)

##### Link reading writing.
function put!(link::Link{T}, val::PoisonOr{T}) where T 
    isa(val, Poison) || write!(link.buffer, val)
    isempty(link.slaves) ? put!(link.channel, val) : foreach(junc -> put!(junc[], val), link.slaves)
    link.callbacks(link)
    return val
end
put!(link::Link{T}, val::PoisonOr{S}) where {T, S} = put!(link, convert(T, val))

function take!(link::Link)
    val = take!(link.channel)
    link.callbacks(link)
    return val
end

function close(link::Link)
    channel = link.channel
    isempty(channel.cond_take.waitq) || put!(link, Poison())   # Terminate taker task 
    isempty(channel.cond_put.waitq) || collect(link.channel)   # Terminater putter task 
    isopen(link.channel) && close(link.channel)  # Close link channel if it is open.
    return link
end

isopen(link::Link) = isopen(link.channel)

##### Auxilary functions to launch links.
function taker(link)
    while true
        val = take!(link)
        val isa Poison && break  # Poison-pill the tasks to terminate safely.
        @info "Took " val
    end
end

function putter(link, vals)
    for val in vals
        put!(link, val)
    end
end

##### Calling link
(link::Link)(t) = take!(link, t)

##### State check of link.
isfull(link::Link) = isfull(link.buffer)
isconnected(l1::Link, l2::Link) = l1.rightpin == l2.leftpin || l1.leftpin == l2.rightpin
snapshot(link::Link) = link.buffer.data
hasslaves(link::Link) = !isempty(link.slaves)
function hasmaster(link::Link) 
    try
        _ = link.master.x
    catch UnderVarError
        return false
    end
    return true
end

##### Connecting and disconnecting links
function connect(srclink::Link, dstlink::Link)
    dstlink.leftpin = srclink.rightpin  # NOTE: The data flows through the links from left to right.
    push!(srclink.slaves, Ref(dstlink))
    dstlink.master = Ref(srclink) 
end

function disconnect(srclink::Link{T}, dstlink::Link{T}) where T
    slaves = srclink.slaves
    for i = 1 : length(slaves)
        slaves[i][] == dstlink && deleteat!(slaves, i)
    end
    dstlink.master = RefValue{Link{T}}()
    dstlink.leftpin = Pin()
end

##### Launching links.
eltype(link::Link{T}) where T = T
launch(link::Link) = (task = @async taker(link); bind(link.channel, task); task)
launch(link::Link, valrange) = (task = @async putter(link, valrange); bind(link.channel, task); task)
launch(link::AbstractLink, taskname::Symbol, valrange) = @warn "`launch(link, taskname, valrange)` has been deprecated. Use `launch(link)` to launch taker task, `launch(link, valrange)` to launch putter task"
