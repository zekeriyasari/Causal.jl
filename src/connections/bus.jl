# This file contains the Bus tool for connecting the tools of DsSimulator

import Base: put!, wait, take!
import Base: size, getindex, setindex!, length, iterate, firstindex, lastindex, close, eltype


"""
    Bus{T}([nlinks::Int=1, [ln::Int=64]]) where T

Constructs a `Bus` consisting of `nlinks` links. `ln` is the buffer length and `T` is element type of the links.
"""
struct Bus{T}
    links::Vector{Link{T}}
    callbacks::Vector{Callback}
    id::UUID
    Bus{T}(nlinks::Int=1, ln::Int=64) where T = 
        new{Union{Missing, T}}([Link{T}(ln) for i = 1 : nlinks], Callback[], uuid4())
end

"""
    Bus([nlinks::Int=1, [ln::Int=64]])

Constructs a `Bus` consisting of `nlinks` links with element type `T`. `ln` is the buffer length of the links.
"""
Bus(nlinks::Int=1, ln::Int=64) = Bus{Float64}(nlinks, ln)

show(io::IO, bus::Bus{Union{Missing, T}})  where T = print(io, "Bus(nlinks:$(length(bus)), eltype:$(T), ",
    "isreadable:$(isreadable(bus)), iswritable:$(iswritable(bus)))")

##### Make bus indexable.
"""
    eltype(bus::Bus)

Returns the element type of `bus`. Element type of `bus` is a subtype of `Link`.

# Example 
```jldoctest
julia> b = Bus{Matrix{Float64}}(5)
Bus(nlinks:5, eltype:Array{Float64,2}, isreadable:false, iswritable:false)

julia> eltype(b)
Link{Union{Missing, Array{Float64,2}}}
```
"""
eltype(bus::Bus{T}) where {T} = Link{T}

"""
    length(bus::Bus)

Returns the number of links in `bus`.

# Example
```jldoctest
julia> b = Bus(5)
Bus(nlinks:5, eltype:Float64, isreadable:false, iswritable:false)

julia> length(b)
5
```
"""
length(bus::Bus) = length(bus.links)
size(bus::Bus) = size(bus.links)

"""
    getindex(bus::Bus, I)

Returns the links of `bus` corresponding to `I`. The syntax `bus[I]` is the same as `getindex(bus, I)`.

# Example
```jldoctest 
julia> b = Bus(3);

julia> b[1]
Link(state:open, eltype:Union{Missing, Float64}, hasmaster:false, numslaves:0, isreadable:false, iswritable:false)

julia> b[1:2]
2-element Array{Link{Union{Missing, Float64}},1}:
 Link(state:open, eltype:Union{Missing, Float64}, hasmaster:false, numslaves:0, isreadable:false, iswritable:false)
 Link(state:open, eltype:Union{Missing, Float64}, hasmaster:false, numslaves:0, isreadable:false, iswritable:false)

julia> b[end]
Link(state:open, eltype:Union{Missing, Float64}, hasmaster:false, numslaves:0, isreadable:false, iswritable:false)
```
"""
getindex
getindex(bus::Bus, I::Int) =  bus.links[I]
getindex(bus::Bus, I::Vector{Int}) =  bus.links[I]
getindex(bus::Bus, I::UnitRange{Int}) = bus.links[I]
getindex(bus::Bus, ::Colon) = bus.links[:]


"""
    setindex!(bus::Bus, val, I::Int) 

Sets `val` to the links of `bus` corresponding to index `I`. The syntax `bus[I] = val` is the same as `setindex!(bus, val, I)`.

# Example 
```jldoctest
julia> b = Bus(5);

julia> b[2:3] .= [Link() for i = 1 : 2]
2-element Array{Link{Union{Missing, Float64}},1}:
 Link(state:open, eltype:Union{Missing, Float64}, hasmaster:false, numslaves:0, isreadable:false, iswritable:false)
 Link(state:open, eltype:Union{Missing, Float64}, hasmaster:false, numslaves:0, isreadable:false, iswritable:false)

julia> b[end] = Link() 
Link(state:open, eltype:Union{Missing, Float64}, hasmaster:false, numslaves:0, isreadable:false, iswritable:false)
```
"""
setindex!
setindex!(bus::Bus, val, I::Int) = bus.links[I] = val
setindex!(bus::Bus, val::AbstractVector, I::Vector{Int}) = bus.links[I] = val
setindex!(bus::Bus, val::AbstractVector, I::UnitRange{Int}) = bus.links[I] = val
setindex!(bus::Bus, val::AbstractVector, ::Colon) = bus.links[:] = val

firstindex(bus::Bus) = 1
lastindex(bus::Bus) = length(bus)  # For indexing like bus[end]

##### Reading from and writing into from buses
"""
    take!(bus::Bus)

Takes an element from `bus`. Each link of the `bus` is a read and a vector containing the results is returned.

!!! warning 
    The `bus` must be readable to be read. That is, there must be a runnable tasks bound to links of the `bus` that writes data to `bus`. See [`launch`](@ref)

# Example 
```julia 
julia> b = Bus(2);

julia> t = launch(b, [[rand() for i = 1 : 5] for j = 1 : 2])
2-element Array{Task,1}:
 Task (runnable) @0x00007f9634734280
 Task (runnable) @0x00007f96347344f0

julia> take!(b)
2-element Array{Float64,1}:
 0.6216364091492494
 0.0781964275368685
```
"""
function take!(bus::Bus) 
    out = take!.(bus.links)
    bus.callbacks(bus)
    out
end

"""
    put!(bus::Bus, vals)

Puts `vals` to `bus`. Each item in `vals` is putted to the `links` of the `bus`.

!!! warning 
    The `bus` must be writable to be read. That is, there must be a runnable tasks bound to links of the `bus` that reads data from `bus`. See [`launch`](@ref)

# Example 
```julia
julia> b = Bus(2);

julia> t = launch(b);

julia> put!(b, [1., 2.])
┌ Info: Took 
└   val = 1.0
┌ Info: Took 
└   val = 2.0
2-element Array{Float64,1}:
 1.0
 2.0
```
"""
function put!(bus::Bus, vals)
    put!.(bus.links, vals)
    bus.callbacks(bus)
    vals
end

##### Iterating bus
"""
    iterate(bus::Bus[, i=1])

İteration interface so that `bus` can be iterated in a loop. The links of `bus` are iterated.

# Example 
```jldoctest
julia> b = Bus(3);

julia> for l in b 
       @show l 
       end
l = Link(state:open, eltype:Union{Missing, Float64}, hasmaster:false, numslaves:0, isreadable:false, iswritable:false)
l = Link(state:open, eltype:Union{Missing, Float64}, hasmaster:false, numslaves:0, isreadable:false, iswritable:false)
l = Link(state:open, eltype:Union{Missing, Float64}, hasmaster:false, numslaves:0, isreadable:false, iswritable:false)
```
"""
iterate(bus::Bus, i=1) = i > length(bus.links) ? nothing : (bus.links[i], i + 1)   # When iterated, return links

##### Interconnection of busses.
"""
    hasslaves(bus:Bus)

Returns `true` is all the links of `bus` has slaves. See also [`hasslaves(link::Link)`](@ref)
"""
hasslaves(bus::Bus) = all(hasslaves.(bus.links))

"""
   hasmaster(bus::Bus) 

Returns `true` is all the links of `bus` has master. See alsos [`hasmaster(link::Link)`](@ref)
"""
hasmaster(bus::Bus) = all(hasmaster.(bus.links))

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
isfull(bus::Bus) = all(isfull.(bus.links))

"""
    isreadable(bus::Bus)

Returns `true` if all the links of `bus` is readable.
"""
isreadable(bus::Bus) = all(isreadable.(bus.links))

"""
    iswritable(bus::Bus)

Returns `true` if all the links of `bus` is writable.
"""
iswritable(bus::Bus) = all(iswritable.(bus.links))

##### Methods on busses.
# clean!(bus::Bus) = foreach(link -> clean!(link.buffer), bus.links)

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
launch(bus::Bus) = launch.(bus.links)

"""
    launch(bus::Bus, valrange::AbstractVector)

Launches every links of `bus` with every item of `valrange`. See [`launch(link:Link, valrange)`(@ref)]
"""
launch(bus::Bus, valrange::AbstractVector) = launch.(bus.links, valrange)
