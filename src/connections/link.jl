# This file contains the links to connect together the tools of DsSimulator.

import Base: put!, take!, RefValue, close, isready, eltype, isopen, isreadable, iswritable, bind, collect, iterate

"""
    Pin() 

Constructs a `Pin`. A `Pin` is the auxilary type to monitor connection status of `Links`. See [`Link`](@ref)
"""
struct Pin
    id::UUID
    Pin() = new(uuid4())
end

"""
    Link{T}([ln::Int=64]) where T 

Constructs a `Link` with element type `T` and buffer length `ln`. The buffer element type of `T` and mode is `Cyclic`.
"""
mutable struct Link{T}
    buffer::Buffer{Cyclic, T}
    channel::Channel{T}
    leftpin::Pin
    rightpin::Pin
    callbacks::Vector{Callback}
    id::UUID
    master::RefValue{Link{T}}
    slaves::Vector{RefValue{Link{T}}}
    Link{T}(ln::Int=64) where {T} = new{T}(Buffer(T, ln), Channel{T}(0), Pin(), Pin(),
        Callback[], uuid4(), RefValue{Link{T}}(), Vector{RefValue{Link{T}}}()) 
end
Link(ln::Int=64) = Link{Float64}(ln)

eltype(link::Link{T}) where T = T

show(io::IO, link::Link) = print(io, 
    "Link(state:$(isopen(link) ? :open : :closed), eltype:$(eltype(link)), hasmaster:$(isassigned(link.master)), ", 
    "numslaves:$(length(link.slaves)), isreadable:$(isreadable(link)), iswritable:$(iswritable(link)))")

##### Link reading writing.
"""
    put!(link::Link, val)

Puts `val` to `link`. `val` is handed over to the `channel` of `link`. `val` is also written in to the `buffer` of `link`.

!!! warning
    `link` must be writable to put `val`. See [`launch`](@ref)

# Example
```julia
julia> l = Link();

julia> t = launch(l);  # To be able to put values, `l` must be bound to a runnable task.

julia> put!(l, 1.)
┌ Info: Took 
└   val = 1.0
1.0
```
"""
function put!(link::Link, val) 
    write!(link.buffer, val)
    isempty(link.slaves) || foreach(junc -> put!(junc[], val), link.slaves)
    put!(link.channel, val)
    link.callbacks(link)
    return val
end

"""
    take!(link::Link)

Take an element from `link`.

!!! warning 
    `link` must be readable to take value. See [`launch`](@ref)

# Example
```julia
julia> l = Link(5);

julia> t = launch(l, 1. : 5.);

julia> for i in 1 : 5
       @show take!(l)
       end
take!(l) = 1.0
take!(l) = 2.0
take!(l) = 3.0
take!(l) = 4.0
take!(l) = 5.0
```
"""
function take!(link::Link)
    val = take!(link.channel)
    link.callbacks(link)
    return val
end

"""
    close(link)

Closes `link`. All the task bound the `link` is also terminated safely. When closed, data cannot ben into or read from the `link`.

# Example
```julia
julia> l  = Link();

julia> t = launch(l);

julia> put!(l, 1.)
┌ Info: Took 
└   val = 1.0
1.0

julia> close(l)

julia> put!(l, 1.)
ERROR: InvalidStateException("Channel is closed.", :closed)
Stacktrace:
 [1] check_channel_state at ./channels.jl:167 [inlined]
 [2] put! at ./channels.jl:323 [inlined]
 [3] put!(::Link{Union{Missing, Float64}}, ::Float64) at /home/sari/.julia/dev/Jusdl/src/connections/link.jl:64
 [4] top-level scope at REPL[99]:1
```
"""
function close(link::Link)
    channel = link.channel
    # isempty(channel.cond_take.waitq) || put!(link, missing)   # Terminate taker task 
    isempty(channel.cond_take.waitq) || put!(link, NaN)   # Terminate taker task 
    isempty(channel.cond_put.waitq) || collect(link.channel)   # Terminater putter task 
    # isopen(link.channel) && close(link.channel)  # Close link channel if it is open.
    return 
end 

##### State check of link.
"""
    open(link::Link)

Returns `true` if `link` is open. A `link` is open if its `channel` is open.
"""
isopen(link::Link) = isopen(link.channel) 

"""
    isreadable(link::Link)

Returns `true` if `link` is readable. When `link` is readable, data can be read from `link` with `take` function.
"""
isreadable(link::Link) = !isempty(link.channel.cond_put)

"""
    writable(link::Link)

Returns `true` if `link` is writable. When `link` is writable, data can be written into `link` with `put` function.
"""
iswritable(link::Link) = !isempty(link.channel.cond_take) 

"""
    isfull(link::Link)

Returns `true` if the `buffer` of `link` is full.
"""
isfull(link::Link) = isfull(link.buffer)


"""
    hasslaves(link::Link)

Returns `true` if `link` has slave links.
"""
hasslaves(link::Link) = !isempty(link.slaves)

"""
    hasmaster(link::Link)

Returns `true` if `link` has a master link.
"""
function hasmaster(link::Link) 
    try
        _ = link.master.x
    catch UnderVarError
        return false
    end
    return true
end

"""
    getmaster(link::Link)

Returns the `master` of `link`.
"""
getmaster(link::Link) = hasmaster(link) ? link.master[] : nothing

"""
    getslaves(link::Link)

Returns the `slaves` of `link`.
"""
getslaves(link::Link) = [slave[] for slave in link.slaves]

"""
    snapshot(link::Link)

Returns all the data of the `buffer` of `link`.
"""
snapshot(link::Link) = link.buffer.data

##### Connecting and disconnecting links
# This `iterate` function is dummy. It is defined just for `[l...]` to be written.
iterate(l::Link, i=1) = i > 1 ? nothing : (l, i + 1)

"""
    connect(master::Link, slave::Link)

Connects `master` to `slave`. When connected, the flow is from `master` to `slave`.

    connect(links...)

Connect each link of `links` in the form of a path.

# Example 
```jldoctest 
julia> l1, l2 = Link(), Link();

julia> isconnected(l1, l2)
false

julia> connect(l1, l2)

julia> isconnected(l1, l2)
true

julia> ls = [Link() for i = 1 : 3];

julia> map(i -> isconnected(ls[i], ls[i + 1]), 1 : 2)
2-element Array{Bool,1}:
 0
 0

julia> connect(ls...)

julia> map(i -> isconnected(ls[i], ls[i + 1]), 1 : 2)
2-element Array{Bool,1}:
 1
 1
```
"""
function connect(master::Link, slave::Link)
    isconnected(master, slave) && (@warn "$master and $slave are already connected."; return)
    slave.leftpin = master.rightpin  # NOTE: The data flows through the links from left to right.
    push!(master.slaves, Ref(slave))
    slave.master = Ref(master) 
    return 
end
connect(master::AbstractVector{<:Link}, slave::AbstractVector{<:Link}) = (connect.(master, slave); nothing)
connect(master, slave) = connect([master...], [slave...])

"""
    disconnect(link1::Link, link2::Link)

Disconnects `link1` and `link2`. The order of arguments is not important. 

# Example
```jldoctest
julia> ls = [Link() for i = 1 : 2];

julia> connect(ls[1], ls[2])

julia> disconnect(ls[1], ls[2])

julia> isconnected(ls[1], ls[2])
false
```
"""
function disconnect(link1::Link{T}, link2::Link{T}) where T
    master, slave = findflow(link1, link2)
    slaves = master.slaves
    deleteat!(slaves, findall(linkref -> linkref[] == slave, slaves))
    slave.master = RefValue{Link{T}}()
    slave.leftpin = Pin()
    return
end
disconnect(link1::AbstractVector{<:Link}, link2::AbstractVector{<:Link}) = (disconnect.(link1, link2); nothing)
disconnect(link1, link2) = disconnect([link1...], [link2...])

"""
    isconnected(link1, link2)

Returns `true` if `link1` is connected to `link2`. The order of the arguments are not important.
"""
isconnected(link1::Link, link2::Link) = link2 in [sl[] for sl in link1.slaves] || link1 in [sl[] for sl in link2.slaves]
isconnected(link1::AbstractVector{<:Link}, link2::AbstractVector{<:Link}) = all(isconnected.(link1, link2))
isconnected(link1, link2) = isconnected([link1...], [link2...])

"""
    UnconnectedLinkError <: Exception

Exception thrown when the links are not connected to each other.
"""
struct UnconnectedLinkError <: Exception
    msg::String
end
Base.showerror(io::IO, err::UnconnectedLinkError) = print(io, "UnconnectedLinkError:\n $(err.msg)")

"""
    findflow(link1::Link, link2::Link)

Returns a tuple of (`masterlink`, `slavelink`) where `masterlink` is the link that drives the other and `slavelink` is the link that is driven by the other.

# Example
```jldoctest
julia> ls = [Link() for i = 1 : 2];

julia> connect(ls[1], ls[2])

julia> findflow(ls[2], ls[1]) .== (ls[1], ls[2])
(true, true)
```
"""
function findflow(link1::Link, link2::Link)
    isconnected(link1, link2) || throw(UnconnectedLinkError("$link1, and $link2 are not connected."))
    link2 in [slave[] for slave in link1.slaves] ? (link1, link2) : (link2, link1)
end


"""
    insert(master::Link, slave::Link, new::Link)

Inserts the `new` link between the `master` link and `slave` link. The `master` is connected to `new`, and `new` is connected to `slave`.

# Example 
```jldoctest
julia> ls = [Link() for i = 1 : 3];  

julia> connect(ls[1], ls[2]) 

julia> insert(ls[1], ls[2], ls[3])

julia> isconnected(ls[1], ls[2])
false

julia> isconnected(ls[1], ls[3]) && isconnected(ls[3], ls[2])
true
```

"""
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
# insert(master::Vector{<:Link}, slave::Vector{<:Link}, new::Vector{<:Link}) = 
#     foreach(l -> insert(l...), zip(master, slave, new))

"""
    release(link::Link)

Release all the slave links of `link`. That is, all the slave links of `link` is disconnected.

# Example
```jldoctest
julia> ls = [Link() for i = 1 : 5];

julia> foreach(l -> connect(ls[1], l), ls[2:5])

julia> map(l -> isconnected(ls[1], l), ls[2:5])
4-element Array{Bool,1}:
 1
 1
 1
 1

julia> release(ls[1])  # Release all the slaves.

julia> map(l -> isconnected(ls[1], l), ls[2:5])
4-element Array{Bool,1}:
 0
 0
 0
 0
```
"""
function release(link::Link)
    while !isempty(link.slaves)
        disconnect(link, link.slaves[1][])
    end
end
release(links::AbstractVector{<:Link}) = foreach(release, links)

##### Launching links.

##### Auxilary functions to launch links.
### The `taker` and `puter` functions are just used for troubleshooting purpose.
function taker(link::Link)
    while true
        val = take!(link)
        val === NaN && break  # Poison-pill the tasks to terminate safely.
        @info "Took " val
    end
end

function putter(link::Link, vals)
    for val in vals
        put!(link, val)
    end
end

"""
    bind(link::Link, task::Task)

Binds `task` to `link`. When `task` is done `link` is closed.
"""
bind(link::Link, task::Task) = bind(link.channel, task)

"""
    collect(link::Link)

Collects all the available data on the `link`.
"""
collect(link::Link) = collect(link.channel)

"""
    launch(link::Link)

Constructs a `taker` task and binds it to `link`. The `taker` task reads the data and prints an info message until `missing` is read from the `link`.
"""
function launch(link::Link) 
    task = @async taker(link)
    bind(link.channel, task)
    task
end

"""
    launch(link:Link, valrange)

Constructs a `putter` task and binds it to `link`. `putter` tasks puts the data in `valrange`.
"""
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
