# This file contains the Pins to connect the links


export AbstractPin, Outpin, Inpin, connect!, disconnect!, isconnected, isbound, 
    ScalarInpin, VectorInpin, ScalarOutpin, VectorOutpin

"""
    $(TYPEDEF)

Abstract type of `Outpin` and `Inpin`. See also: [`Outpin`](@ref), [`Inpin`](@ref)
"""
abstract type AbstractPin{T} end


"""
    $(TYPEDEF) 

# Fields 

    $(TYPEDFIELDS)
"""
mutable struct Outpin{T} <: AbstractPin{T}
    links::Union{Vector{Link{T}}, Missing}
    id::UUID
    # NOTE: When Outpin is initialized, its links are missing. 
    # The existance of links of Outpin is used to determine 
    # whether the Outpin is bound or not.
    Outpin{T}() where {T} = new{T}(missing, uuid4())
end
Outpin() = Outpin{Float64}()

show(io::IO, outpin::Outpin) = print(io, "Outpin(eltype:$(eltype(outpin)), isbound:$(isbound(outpin)))")

"""
    $(TYPEDEF) 

# Fields 

    $(TYPEDFIELDS)

Constructs and `InPut` pin. The data flow from `Inpin` is inwards to the pin i.e., data is read from links of `InPort`.
"""
mutable struct Inpin{T} <: AbstractPin{T}
    link::Union{Link{T}, Missing}
    id::UUID
    # NOTE: When an Inpin is initialized, its link is missing. 
    # The state of link of the Inpin is used to decide whether the Inpin is bound or not. 
    Inpin{T}() where {T} = new{T}(missing, uuid4())
end
Inpin() = Inpin{Float64}()

show(io::IO, inpin::Inpin) = print(io, "Inpin(eltype:$(eltype(inpin)), isbound:$(isbound(inpin)))")


# Some short-hand notations 
const ScalarInpin = Inpin{Float64}
const VectorInpin = Inpin{Vector{Float64}}
const ScalarOutpin = Outpin{Float64} 
const VectorOutpin = Outpin{Vector{Float64}}


"""
    $(SIGNATURES) 

Binds `link` to `pin`. When bound, data written into or read from `pin` is written into or read from `link`.
"""
bind(link::Link, inpin::Inpin) = (inpin.link = link; link.slaveid = inpin.id)
bind(link::Link, outpin::Outpin) = (outpin.links === missing ? (outpin.links = [link]) : push!(outpin.links, link); link.masterid = outpin.id)

"""
    $(SIGNATURES) 

Returns `true` if `pin` is bound to other pins.
"""
function isbound(outpin::Outpin)
    outpin.links === missing && return false
    !isempty(outpin.links)
end
isbound(inpin::Inpin) = inpin.link !== missing

"""
    $(SIGNATURES) 

Returns element typef of pin.
"""
eltype(pin::AbstractPin{T}) where T = T

"""
    $(SIGNATURES) 

Takes data from `pin`. The data is taken from the links of `pin`.

!!! warning
    To take data from `pin`, a running task that puts data must be bound to `link` of `pin`.

# Example 
```julia
julia> ip = Inpin();

julia> l = Link();

julia> bind(l, ip);

julia> t = @async for item in 1 : 5 
       put!(l, item)
       end;

julia> take!(ip)
1.0

julia> take!(ip)
2.0
```
"""
take!(pin::Inpin) = take!(pin.link)

"""
    $(SIGNATURES) 

Puts `val` to `pin`. `val` is put into the links of `pin`.

!!! warning
    To take data from `pin`, a running task that puts data must be bound to `link` of `pin`.

# Example 
```julia
julia> op = Outpin();

julia> l = Link();

julia> bind(l, op);

julia> t = @async while true 
       val = take!(l) 
       val === NaN && break
       println("Took " * string(val))
       end;

julia> put!(op, 1.)
Took 1.0

julia> put!(op, 3.)
Took 3.0

julia> put!(op, NaN)
```
"""
put!(pin::Outpin, val) = foreach(link -> put!(link, val), pin.links)


##### Connecting and disconnecting links
"""
    $(SIGNATURES)

Connects `outpin` to `inpin`. When connected, any element that is put into `outpin` is also put into `inpin`. 

# Example 
```julia 
julia> op, ip = Outpin(), Inpin();

julia> l = connect!(op, ip)
Link(state:open, eltype:Float64, isreadable:false, iswritable:false)

julia> l in op.links
true

julia> ip.link === l
true
```
"""
function connect!(outpin::Outpin, inpin::Inpin)
    # NOTE: The connecion of an `Outpin` to multiple `Inpin`s is possible since an `Outpin` may drive multiple 
    # `Inpin`s. However, the connection of multiple `Outpin`s to the same `Inpin` is NOT possible since an `Inpin` 
    # can be driven by a single `Outpin`. 
    isbound(inpin) && error("$inpin is already bound. No new connections.")
    isconnected(outpin, inpin) && (@warn "$outpin and $inpin are already connected."; return)

    link = Link{promote_type(eltype(outpin), eltype(inpin))}()
    bind(link, outpin)
    bind(link, inpin)
    return link
end
connect!(outpins::AbstractVector{<:Outpin}, inpins::AbstractVector{<:Inpin}) = connect!.(outpins, inpins)

"""
    $(SIGNATURES) 

Disconnects `link1` and `link2`. The order of arguments is not important. See also: [`connect!`](@ref)
"""
function disconnect!(outpin::Outpin, inpin::Inpin)
    outpin.links === missing || deleteat!(outpin.links, findall(link -> link == inpin.link, outpin.links))
    inpin.link = missing
    # inpin.link = Link{eltype(inpin)}()
end
disconnect!(outpins::AbstractVector{<:Outpin}, inpins::AbstractVector{<:Inpin}) = (disconnect!.(outpins, inpins); nothing)


"""
    $(SIGNATURES) 

Returns `true` if `link1` is connected to `link2`. The order of the arguments are not important. 
See also [`connect!`](@ref), [`disconnect!`](@ref)
"""
function isconnected(outpin::Outpin, inpin::Inpin)
    if !isbound(outpin) || !isbound(inpin)
        return false
    else
        inpin.link in [link for link in outpin.links]
    end
end
isconnected(outpins::AbstractVector{<:Outpin}, inpins::AbstractVector{<:Inpin}) = all(isconnected.(outpins, inpins))

# ------------------------ Deprecations  -----------------------

#= NOTE:
The methods 

    connect!(outpins, inpins) = connect!([outpins...], [inpins...])
    disconnect!(outpins, inpins) = disconnect!([outpins...], [inpins...])
    isconnected(outpins, inpins) = isconnected([outpins...], [inpins...])

are ambiguis. Since these methods throws StackOverflowError when called with `outpins` are `Inpin`s and 
inpins are `Outpin`s. So, there is not need for 

    iterate(l::AbstractPin, i=1) = i > 1 ? nothing : (l, i + 1)

method-
=#

# """
#     UnconnectedLinkError <: Exception

# Exception thrown when the links are not connected to each other.
# """
# struct UnconnectedLinkError <: Exception
#     msg::String
# end
# Base.showerror(io::IO, err::UnconnectedLinkError) = print(io, "UnconnectedLinkError:\n $(err.msg)")
