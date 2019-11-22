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
Link(ln::Int=64) = Link{Float64}(ln)

eltype(link::Link{T}) where T = T

show(io::IO, link::Link) = print(io, 
    "Link(state:$(isopen(link) ? :open : :closed), eltype:$(eltype(link)), hasmaster:$(isassigned(link.master)), ", 
    "numslaves:$(length(link.slaves)), isreadable:$(isreadable(link)), iswritable:$(iswritable(link)))")

##### Link reading writing.
function put!(link::Link, val) 
    write!(link.buffer, val)
    isempty(link.slaves) || foreach(junc -> put!(junc[], val), link.slaves)
    put!(link.channel, val)
    link.callbacks(link)
    return val
end

function take!(link::Link)
    val = take!(link.channel)
    link.callbacks(link)
    return val
end

function close(link::Link)
    channel = link.channel
    isempty(channel.cond_take.waitq) || put!(link, missing)   # Terminate taker task 
    isempty(channel.cond_put.waitq) || collect(link.channel)   # Terminater putter task 
    # isopen(link.channel) && close(link.channel)  # Close link channel if it is open.
    return 
end 

##### Auxilary functions to launch links.
function taker(link::Link)
    while true
        val = take!(link)
        val isa Missing && break  # Poison-pill the tasks to terminate safely.
        @info "Took " val
    end
end

function putter(link::Link, vals)
    for val in vals
        put!(link, val)
    end
end

##### State check of link.
isopen(link::Link) = isopen(link.channel) 
isreadable(link::Link) = !isempty(link.channel.cond_put)
iswritable(link::Link) = !isempty(link.channel.cond_take) 
isfull(link::Link) = isfull(link.buffer)
isconnected(link1::Link, link2::Link) = 
    link2 in [slave[] for slave in link1.slaves] || link1 in [slave[] for slave in link2.slaves]
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
function connect(master::Link, slave::Link)
    isconnected(master, slave) && (@warn "$master and $slave are already connected."; return)
    slave.leftpin = master.rightpin  # NOTE: The data flows through the links from left to right.
    push!(master.slaves, Ref(slave))
    slave.master = Ref(master) 
    return 
end
function connect(master::AbstractVector{<:Link}, slave::AbstractVector{<:Link})
    foreach(pair -> connect(pair[1], pair[2]), zip(master, slave))
end
function connect(links::Link...)
    for i = 1 : length(links) - 1
        connect(links[i], links[i + 1])
    end
end

struct UnconnectedLinkError <: Exception
    msg::String
end
Base.showerror(io::IO, err::UnconnectedLinkError) = print(io, "UnconnectedLinkError:\n $(err.msg)")

function findflow(link1::Link, link2::Link)
    isconnected(link1, link2) || throw(UnconnectedLinkError("$link1, and $link2 are not connected."))
    link2 in [slave[] for slave in link1.slaves] ? (link1, link2) : (link2, link1)
end

function disconnect(link1::Link{T}, link2::Link{T}) where T
    master, slave = findflow(link1, link2)
    slaves = master.slaves
    deleteat!(slaves, findall(linkref -> linkref[] == slave, slaves))
    slave.master = RefValue{Link{T}}()
    slave.leftpin = Pin()
    return
end

function insert(master::Link, slave::Link, new::Link)
    if isconnected(master, slave)
        master, slave = findflow(master, slave)
        disconnect(master, slave)
    else
        master, slave = master, slave
    end
    connect(master, new)
    connect(new, slave)
    return
end

# release(masterlink::Link) = foreach(slavelinkref -> disconnect(masterlink, slavelinkref[]), masterlink.slaves)
function release(link::Link)
    while !isempty(link.slaves)
        disconnect(link, link.slaves[1][])
    end
end

##### Launching links.
function launch(link::Link) 
    task = @async taker(link)
    bind(link.channel, task)
    task
end
function launch(link::Link, valrange)
    task = @async putter(link, valrange) 
    bind(link.channel, task) 
    task
end
function launch(link::Link, taskname::Symbol, valrange)
    msg = "`launch(link, taskname, valrange)` has been deprecated."
    msg *= "Use `launch(link)` to launch taker task, `launch(link, valrange)` to launch putter task"
    @warn msg
end
