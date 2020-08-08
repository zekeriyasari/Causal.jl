# This file contains the Pins to connect the links


"""
    AbstractPin{T} 

Abstract type of `Outpin` and `Inpin`. See also: [`Outpin`](@ref), [`Inpin`](@ref)
"""
abstract type AbstractPin{T} end


"""
    Outpin{T}()

Constructs and `OutPut` pin. The data flow from `Outpin` is outwards from the pin i.e., data is written from `OutPort` to its links.
"""
struct Outpin{T} <: AbstractPin{T}
    id::UUID
    links::Vector{Link{T}}
    Outpin{T}() where T = new{T}(uuid4(), Vector{Link{T}}())
end
Outpin() = Outpin{Float64}()

show(io::IO, outpin::Outpin) = print(io, "Outpin(eltype:$(eltype(outpin)), isbound:$(isbound(outpin)))")

"""
    Inpin{T}()

Constructs and `InPut` pin. The data flow from `Inpin` is inwards to the pin i.e., data is read from links of `InPort`.
"""
mutable struct Inpin{T} <: AbstractPin{T}
    id::UUID
    link::Link{T}
    Inpin{T}() where T = new{T}(uuid4())
end
Inpin() = Inpin{Float64}()

show(io::IO, inpin::Inpin) = print(io, "Inpin(eltype:$(eltype(inpin)), isbound:$(isbound(inpin)))")

"""
    bind(link::Link, pin)

Binds `link` to `pin`. When bound, data written into or read from `pin` is written into or read from `link`.
"""
bind(link::Link, inpin::Inpin) = (inpin.link = link; link.slaveid = inpin.id)
bind(link::Link, outpin::Outpin) = (push!(outpin.links, link); link.masterid = outpin.id)

"""
    isbound(pin::AbstractPin)

Returns `true` if `outpin` is bound to a `Link`.
"""
isbound(outpin::Outpin) = length(outpin.links) > 0
function isbound(inpin::Inpin)
    try
        _ = inpin.link
        return true
    catch UndefRefError
        return false
    end
end

"""
    eltype(pin::AbstractPin)

Returns element typef of pin.
"""
eltype(pin::AbstractPin{T}) where T = T

"""
    take!(pin::Inpin)

Takes data from `pin`. The data is taken from the links of `pin`.

!!! warning
    To take data from `pin`, a running task that puts data must be bound to `link` of `pin`.

# Example 
```jldoctest
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
    put!(pin::Outpin, val)

Puts `val` to `pin`. `val` is put into the links of `pin`.

!!! warning
    To take data from `pin`, a running task that puts data must be bound to `link` of `pin`.

# Example 
```jldoctest
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
#
# This `iterate` function is dummy. It is defined just for `[l...]` to be written.
#
iterate(l::AbstractPin, i=1) = i > 1 ? nothing : (l, i + 1)

"""
    connect!(outpin::Link, inpin::Link)

Connects `outpin` to `inpin`. When connected, any element that is put into `outpin` is also put into `inpin`. 

    connect!(outpin::AbstractVector{<:Link}, inpin::AbstractVector{<:Link})

Connects each link in `outpin` to each link in `inpin` one by one. See also: [`disconnect!`](@ref)

# Example 
```jldoctest 
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
connect!(outpins, inpins) = connect!([outpins...], [inpins...])

"""
    disconnect!(link1::Link, link2::Link)

Disconnects `link1` and `link2`. The order of arguments is not important. See also: [`connect!`](@ref)
"""
function disconnect!(outpin::Outpin, inpin::Inpin)
    deleteat!(outpin.links, findall(link -> link == inpin.link, outpin.links))
    inpin.link = Link{eltype(inpin)}()
end
disconnect!(outpins::AbstractVector{<:Outpin}, inpins::AbstractVector{<:Inpin}) = (disconnect!.(outpins, inpins); nothing)
disconnect!(outpins, inpins) = disconnect!([outpins...], [inpins...])


"""
    isconnected(link1, link2)

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
isconnected(outpins, inpins) = isconnected([outpins...], [inpins...])

"""
    UnconnectedLinkError <: Exception

Exception thrown when the links are not connected to each other.
"""
struct UnconnectedLinkError <: Exception
    msg::String
end
Base.showerror(io::IO, err::UnconnectedLinkError) = print(io, "UnconnectedLinkError:\n $(err.msg)")
