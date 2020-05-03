# This file contains the Port tool for connecting the tools of Jusdl


"""
    AbstractPort{P}

Abstract type of [`Outport`](@ref) and [`Inport`](@ref). See also: [`Outport`](@ref), [`Inport`](@ref).
"""
abstract type AbstractPort{P} <: AbstractVector{P} end


"""
    Outport{T}(numpins=1) 

Constructs an `Outport` with `numpins` [`Outpin`](@ref).

!!! warning
    Element type of an `Outport` must be `Outpin`. See also [`Outpin`](@ref)

# Example 
```jldoctest
julia> Outport{Int}(2)
2-element Outport{Outpin{Int64}}:
 Outpin(eltype:Int64, isbound:false)
 Outpin(eltype:Int64, isbound:false)

julia> Outport()
1-element Outport{Outpin{Float64}}:
 Outpin(eltype:Float64, isbound:false)
```
"""
struct Outport{P} <: AbstractPort{P}
    pins::Vector{P}
    id::UUID
    Outport(pins::AbstractVector{P}) where {T, P<:Outpin{T}} = new{P}(pins, uuid4())
end
Outport(pin::Outpin) = Outport([pin])
Outport{T}(numpins::Int=1) where T = Outport([Outpin{T}() for i = 1 : numpins]) 
Outport(numpins::Int=1) = Outport{Float64}(numpins)

show(io::IO, outport::Outport) = print(io, "Outport(numpins:$(length(outport)), eltype:$(eltype(outport)))")
# display(outport::Outport) = println("Outport(numpins:$(length(outport)), eltype:$(eltype(outport)))")


"""
    Inport{T}(numpins=1) 

Constructs an `Inport` with `numpins` [`Inpin`](@ref).

!!! warning
    Element type of an `Inport` must be `Inpin`. See also [`Inpin`](@ref)

# Example 
```jldoctest
julia> Inport{Int}(2)
2-element Inport{Inpin{Int64}}:
 Inpin(eltype:Int64, isbound:false)
 Inpin(eltype:Int64, isbound:false)

julia> Inport()
1-element Inport{Inpin{Float64}}:
 Inpin(eltype:Float64, isbound:false)
```
"""
struct Inport{P} <: AbstractPort{P}
    pins::Vector{P}
    Inport(pins::AbstractVector{P}) where {T, P<:Inpin{T}} = new{P}(pins)
end
Inport(pin::Inpin) = Inport([pin])
Inport{T}(numpins::Int=1) where T = Inport([Inpin{T}() for i = 1 : numpins])
Inport(numpins::Int=1) = Inport{Float64}(numpins)

show(io::IO, inport::Inport) = print(io, "Inport(numpins:$(length(inport)), eltype:$(eltype(inport)))")
# display(inport::Inport) = println("Inport(numpins:$(length(inport)), eltype:$(eltype(inport)))")


"""
    datatype(port::AbstractPort)

Returns the data type of `port`.
"""
datatype(port::AbstractPort{<:AbstractPin{T}}) where T = T

##### AbstractVector interface
"""
    size(port::AbstractPort)

Retruns size of `port`.
"""
size(port::AbstractPort) = size(port.pins)

"""
    getindex(port::AbstractPort, idx::Vararg{Int, N}) where N 

Returns elements from `port` at index `idx`. Same as `port[idx]`.

# Example
```jldoctest
julia> op = Outport(3)
3-element Outport{Outpin{Float64}}:
 Outpin(eltype:Float64, isbound:false)
 Outpin(eltype:Float64, isbound:false)
 Outpin(eltype:Float64, isbound:false)

julia> op[1]
Outpin(eltype:Float64, isbound:false)

julia> op[end]
Outpin(eltype:Float64, isbound:false)

julia> op[:]
3-element Array{Outpin{Float64},1}:
 Outpin(eltype:Float64, isbound:false)
 Outpin(eltype:Float64, isbound:false)
 Outpin(eltype:Float64, isbound:false)
```
"""
getindex(port::AbstractPort, idx::Vararg{Int, N}) where N = port.pins[idx...]

"""
    setindex!(port::AbstractPort, item, idx::Vararg{Int, N}) where N 

Sets `item` to `port` at index `idx`. Same as `port[idx] = item`.

# Example
```jldoctest
julia> op = Outport(3)
3-element Outport{Outpin{Float64}}:
 Outpin(eltype:Float64, isbound:false)
 Outpin(eltype:Float64, isbound:false)
 Outpin(eltype:Float64, isbound:false)

julia> op[1] = Outpin()
Outpin(eltype:Float64, isbound:false)

julia> op[end] = Outpin()
Outpin(eltype:Float64, isbound:false)

julia> op[1:2] = [Outpin(), Outpin()]
2-element Array{Outpin{Float64},1}:
 Outpin(eltype:Float64, isbound:false)
 Outpin(eltype:Float64, isbound:false)
```
"""
setindex!(port::AbstractPort, item, idx::Vararg{Int, N}) where N = port.pins[idx...] = item

##### Reading from and writing into from buses
"""
    take!(inport::Inport)

Takes an element from `inport`. Each link of the `inport` is a read and a vector containing the results is returned.

!!! warning 
    The `inport` must be readable to be read. That is, there must be a runnable tasks bound to links of the `inport` that writes data to `inport`.

# Example 
```jldoctest 
julia> op, ip = Outport(), Inport()
(Outport(numpins:1, eltype:Outpin{Float64}), Inport(numpins:1, eltype:Inpin{Float64}))

julia> ls = connect(op, ip)
1-element Array{Link{Float64},1}:
 Link(state:open, eltype:Float64, isreadable:false, iswritable:false)

julia> t = @async for val in 1 : 5 
       put!(op, [val])
       end;

julia> take!(ip)
1-element Array{Float64,1}:
 1.0

julia> take!(ip)
1-element Array{Float64,1}:
 2.0
```
"""
take!(inport::Inport) = take!.(inport[:])

"""
    put!(outport::Outport, vals)

Puts `vals` to `outport`. Each item in `vals` is putted to the `links` of the `outport`.

!!! warning 
    The `outport` must be writable to be read. That is, there must be a runnable tasks bound to links of the `outport` that reads data from `outport`.

# Example
```jldoctest
julia> op, ip = Outport(), Inport() 
(Outport(numpins:1, eltype:Outpin{Float64}), Inport(numpins:1, eltype:Inpin{Float64}))

julia> ls = connect(op, ip)
1-element Array{Link{Float64},1}:
 Link(state:open, eltype:Float64, isreadable:false, iswritable:false)

julia> t = @async while true 
       val = take!(ip)
       all(val .=== NaN) && break 
       println("Took " * string(val))
       end;

julia> put!(op, [1.])
Took [1.0]
1-element Array{Float64,1}:
 1.0

julia> put!(op, [NaN])
1-element Array{Float64,1}:
 NaN
```
"""
function put!(outport::Outport, vals)
    put!.(outport[:], vals)
    vals
end

##### Interconnection of busses.
"""
    similar(port, numpins::Int=length(outport)) where {P<:Outpin{T}} where {T}

Returns a new port that is similar to `port` with the same element type. The number of links in the new port is `nlinks` and data buffer length is `ln`.
"""
similar(outport::Outport{P}, numpins::Int=length(outport)) where {P<:Outpin{T}} where {T} = Outport{T}(numpins)
similar(inport::Inport{P}, numpins::Int=length(inport)) where {P<:Inpin{T}} where {T} = Inport{T}(numpins)

