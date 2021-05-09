# This file contains the links to connect together the tools of DsSimulator.
import Base: put!, take!, close, isready, eltype, isopen, isreadable, iswritable, bind, collect, iterate

"""
    $TYPEDEF

A `Link` connects an Outpin and Inpin for data flow. See [`Outpin`](@ref), [`Inpin`](@ref), [`connect!`](@ref)

# Fields 

    $TYPEDFIELDS

# Example
```jldoctest
julia> l = Link{Int}(5)
Link(state:open, eltype:Int64, isreadable:false, iswritable:false)

julia> l = Link{Bool}()
Link(state:open, eltype:Bool, isreadable:false, iswritable:false)
```
"""
mutable struct Link{T}
    "Internal buffer to record data flowing throgh link"
    buffer::Buffer{Cyclic, T, 1}
    "Internal channel for data flow"
    channel::Channel{T}
    "Unique identifier of the outpin of the source of the link"
    masterid::UUID
    "Unique identifier fo the inpin of the destination of the link"
    slaveid::UUID
    "Unique identifier"
    id::UUID
    Link{T}(ln::Int=64) where {T} = new{T}(Buffer(T, ln), Channel{T}(0), uuid4(), uuid4(), uuid4())
end
Link(ln::Int=64) = Link{Float64}(ln)


show(io::IO, link::Link) = print(io, "Link(state:$(isopen(link) ? :open : :closed), eltype:$(eltype(link)), ", 
    "isreadable:$(isreadable(link)), iswritable:$(iswritable(link)))")

"""
    $SIGNATURES

Returns element type of `link`.
"""
eltype(link::Link{T}) where {T} = T

##### Link reading writing.
"""
    $SIGNATURES

Puts `val` to `link`. `val` is handed over to the `channel` of `link`. `val` is also written in to the `buffer` of `link`.

!!! warning
    `link` must be writable to put `val`. That is, a runnable task that takes items from the link must be bounded to `link`.

# Example
```jldoctest
julia> l = Link();

julia> t  = @async while true 
       item = take!(l)
       item === NaN && break 
       println("Took " * string(item))
       end;

julia> bind(l, t);

julia> put!(l, 1.)
Took 1.0
1.0

julia> put!(l, 2.)
Took 2.0
2.0

julia> put!(l, NaN)
NaN
```
"""
function put!(link::Link, val) 
    write!(link.buffer, val)
    put!(link.channel, val)
end


"""
    $SIGNATURES

Take an element from `link`.

!!! warning 
    `link` must be readable to take value. That is, a runnable task that puts items from the link must be bounded to `link`.

# Example
```jldoctest
julia> l = Link(5);

julia> t = @async for item in 1. : 5.
       put!(l, item)
       end;

julia> bind(l, t);

julia> take!(l)
1.0

julia> take!(l)
2.0
```
"""
function take!(link::Link)
    val = take!(link.channel)
    return val
end

"""
    $SIGNATURES


Closes `link`. All the task bound the `link` is also terminated safely. When closed, it is not possible to take and put element from the `link`. See also: [`take!(link::Link)`](@ref), [`put!(link::Link, val)`](@ref)
```
"""
function close(link::Link)
    channel = link.channel
    iswritable(link) && put!(link, NaN)   # Terminate taker task 
    isreadable(link) && collect(link.channel)   # Terminater putter task 
    isopen(link) && close(link.channel)  # Close link channel if it is open.
    return 
end 

##### State check of link.
"""
    $SIGNATURES

Returns `true` if `link` is open. A `link` is open if its `channel` is open.
"""
isopen(link::Link) = isopen(link.channel) 

"""
    $SIGNATURES

Returns `true` if `link` is readable. When `link` is readable, data can be read from `link` with `take` function.
"""
isreadable(link::Link) = length(link.channel.cond_put.waitq) > 0

"""
    $SIGNATURES

Returns `true` if `link` is writable. When `link` is writable, data can be written into `link` with `put` function.
"""
iswritable(link::Link) = length(link.channel.cond_take.waitq) > 0

"""
    $SIGNATURES

Returns `true` if the `buffer` of `link` is full.
"""
isfull(link::Link) = isfull(link.buffer)

"""
    $SIGNATURES

Returns all the data of the `buffer` of `link`.
"""
snapshot(link::Link) = link.buffer.data

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
    $SIGNATURES

Binds `task` to `link`. When `task` is done `link` is closed.
"""
bind(link::Link, task::Task) = bind(link.channel, task)

"""
    $SIGNATURES

Collects all the available data on the `link`.

!!! warning 
    To collect all available data from `link`, a task must be bounded to it.

# Example
```jldoctest
julia> l = Link();  # Construct a link.

julia> t = @async for item in 1 : 5  # Construct a task
       put!(l, item)
       end;

julia> bind(l, t);  # Bind it to the link.

julia> take!(l)  # Take element from link.
1.0

julia> take!(l)  # Take again ...
2.0

julia> collect(l)  # Collect remaining data.
3-element Array{Float64,1}:
 3.0
 4.0
 5.0
```
"""
collect(link::Link) = collect(link.channel)

"""
    $SIGNATURES

Constructs a `taker` task and binds it to `link`. The `taker` task reads the data and prints an info message until `missing` is read from the `link`.
"""
function launch(link::Link) 
    task = @async taker(link)
    bind(link.channel, task)
    task
end

"""
    $SIGNATURES

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

"""
    $SIGNATURES

Reconstructst the channel of `link` is its channel is closed.
"""
refresh!(l::Link{T}) where {T} = (l.channel = Channel{T}(); l)

"""
    $(SIGNATURES)

Cleans the data on `link`. 
"""
clean!(link::Link) = (clean!(link.buffer); link)

