# This file contains the links to connect together the tools of DsSimulator.

import Base: put!, take!, RefValue, close, isready, eltype, isopen, isreadable, iswritable


struct Pin
    id::UUID
    Pin() = new(uuid4())
end


mutable struct Link{T}
    buffer::Buffer{Cyclic, T}
    channel::Channel{T}
    leftpin::Pin
    rightpin::Pin
    callbacks::Vector{Callback}
    id::UUID
    master::RefValue{Link{T}}
    slaves::Vector{RefValue{Link{T}}}
    Link{T}(ln::Int=64) where {T} = new{Union{Missing, T}}(Buffer(T, ln), Channel{Union{Missing, T}}(0), Pin(), Pin(),
        Callback[], uuid4(), RefValue{Link{Union{Missing,T}}}(), Vector{RefValue{Link{Union{Missing, T}}}}()) 
end
Link(ln=64) = Link{Float64}(ln)

show(io::IO, link::Link{Union{Missing, T}}) where T = print(io, 
    "Link(state:$(isopen(link) ? :open : :closed), eltype:$(T), hasmaster:$(isassigned(link.master)), ", 
    "numslaves:$(length(link.slaves)), isreadable:$(isreadable(link)), iswritable:$(iswritable(link)))")

##### Link reading writing.
function put!(link::Link{Union{Missing, T}}, val::Union{Missing, T}) where T 
    write!(link.buffer, val)
    isempty(link.slaves) || foreach(junc -> put!(junc[], val), link.slaves)
    put!(link.channel, val)
    # isempty(link.slaves) ? put!(link.channel, val) : foreach(junc -> put!(junc[], val), link.slaves)
    link.callbacks(link)
    return val
end
put!(link::Link{Union{Missing, T}}, val::Union{Missing, S}) where {T, S} = put!(link, convert(T, val))

function take!(link::Link)
    val = take!(link.channel)
    link.callbacks(link)
    return val
end

function close(link::Link)
    channel = link.channel
    isempty(channel.cond_take.waitq) || put!(link, missing)   # Terminate taker task 
    isempty(channel.cond_put.waitq) || collect(link.channel)   # Terminater putter task 
    isopen(link.channel) && close(link.channel)  # Close link channel if it is open.
    return 
end 

##### Auxilary functions to launch links.
function taker(link)
    while true
        val = take!(link)
        val isa Missing && break  # Poison-pill the tasks to terminate safely.
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
isopen(link::Link) = isopen(link.channel) 
isreadable(link::Link) = !isempty(link.channel.cond_put)
iswritable(link::Link) = !isempty(link.channel.cond_take) 
isfull(link::Link) = isfull(link.buffer)
isconnected(l1::Link, l2::Link) = l1.rightpin == l2.leftpin || l1.leftpin == l2.rightpin
hasslaves(link::Link) = !isempty(link.slaves)
function hasmaster(link::Link) 
    try
        _ = link.master.x
    catch UnderVarError
        return false
    end
    return true
end
snapshot(link::Link) = link.buffer.data

##### Connecting and disconnecting links
function connect(srclink::Link, dstlink::Link)
    isconnected(srclink, dstlink) && (@warn "$srclink and $dstlink are already connected."; return)
    dstlink.leftpin = srclink.rightpin  # NOTE: The data flows through the links from left to right.
    push!(srclink.slaves, Ref(dstlink))
    dstlink.master = Ref(srclink) 
    return 
end

function disconnect(srclink::Link{T}, dstlink::Link{T}) where T
    isconnected(srclink, dstlink) || (@warn "$srclink and $dstlink are already disconnected."; return)
    slaves = srclink.slaves
    # for i = 1 : length(slaves)
    #     slaves[i][] == dstlink && deleteat!(slaves, i)
    # end
    deleteat!(slaves, findall(slave -> slave[] == dstlink, slaves))
    dstlink.master = RefValue{Link{T}}()
    dstlink.leftpin = Pin()
    return
end

release(masterlink::Link) = foreach(slavelinkref -> disconnect(masterlink, slavelinkref[]), masterlink.slaves)

##### Launching links.
eltype(link::Link{T}) where T = T
launch(link::Link) = (task = @async taker(link); bind(link.channel, task); task)
launch(link::Link, valrange) = (task = @async putter(link, valrange); bind(link.channel, task); task)
function launch(link::Link, taskname::Symbol, valrange)
    msg = "`launch(link, taskname, valrange)` has been deprecated."
    msg *= "Use `launch(link)` to launch taker task, `launch(link, valrange)` to launch putter task"
    @warn msg
end
