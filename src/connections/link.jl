# This file contains the links to connect together the tools of DsSimulator.

import Base: put!, take!

struct Pin
    id::UUID
end
Pin() = Pin(uuid4())

# Caution: Do not parametrize the Link type since the blocks are connected to each other via `Link`s. Since 
# the connection is done through the mutation of the `master` and `slaves` fields, the `Link` object should not 
# be parametrized. Note also that the data flowing through the `Link` is of type Float64.

mutable struct Link <: AbstractLink
    weight::Float64 
    buffer::Buffer{Cyclic, Float64,1}
    channel::Channel{Float64}
    leftpin::Pin
    rightpin::Pin 
    callbacks::Vector{Callback}
    id::UUID
    master::Base.RefValue{Link}
    slaves::Vector{Base.RefValue{Link}}
end
Link(weight=1.) = Link(weight, Buffer(64), Channel{Float64}(0), Pin(), Pin(), Callback[], uuid4(), 
    Base.RefValue{Link}(), Vector{Base.RefValue{Link}}())

##### Link reading writing.
function put!(link::Link, val)
    write!(link.buffer, val)
    isempty(link.slaves) ? put!(link.channel, val) : foreach(junc -> put!(junc[], val), link.slaves)
    link.callbacks(link)
    val
end

function take!(link::Link)
    val = take!(link.channel)
    link.callbacks(link)
    val
end
take!(link::Link, t) = take!(link.channel) * link.weight

##### Auxilary functions to launch links.
function taker(link)
    while true
        val = take!(link)
        val === NaN && break
        @info "Took " val
    end
end

function putter(link, valrange::AbstractRange)
    for val in valrange
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
    dstlink.leftpin = srclink.rightpin
    push!(srclink.slaves, Ref(dstlink))
    dstlink.master = Ref(srclink) 
end

function disconnect(srclink::Link, dstlink::Link)
    slaves = srclink.slaves
    for i = 1 : length(slaves)
        slaves[i][] == dstlink && deleteat!(slaves, i)
    end
end

##### Launching links.
function launch(link::AbstractLink, taskname::Symbol, valrange=nothing)
    if taskname == :putter
        return @async putter(link, valrange)
    elseif taskname == :taker
        return @async taker(link)
    else
        error("Expected :putter or :taker, got $taskname")
    end
end
