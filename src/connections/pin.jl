# This file contains the Pins to connect the links


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
    bind(link::Link, inpin::Inpin)

Binds `link` to `inpin`. When bound, any value taken from `inpin` is taken from `link`.

    bind(link::Link, outpin::Outpin)

Binds `link` to `pin`.
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

Takes an element from `pin`. The value is taken from the links of `pin`.
"""
take!(pin::Inpin) = take!(pin.link)

"""
    put!(pin::Outpin, val)

Writer `val` to `pin`. `val` is written to the links of `pin`.
"""
put!(pin::Outpin, val) = foreach(link -> put!(link, val), pin.links)


##### Connecting and disconnecting links
#
# This `iterate` function is dummy. It is defined just for `[l...]` to be written.
#
iterate(l::AbstractPin, i=1) = i > 1 ? nothing : (l, i + 1)

"""
    connect(outpin::Link, inpin::Link)

Connects `outpin` to `inpin`. When connected, any element that is put into `outpin` is also put into `inpin`. 

    connect(outpin::AbstractVector{<:Link}, inpin::AbstractVector{<:Link})

Connects each link in `outpin` to each link in `inpin` one by one.

# Example 
```jldoctest 
julia> op, ip = Outpin(), Inpin();

julia> l = connect(op, ip)
Link(state:open, eltype:Float64, isreadable:false, iswritable:false)

julia> l in op.links
true

julia> ip.link === l
true
```
"""
function connect(outpin::Outpin, inpin::Inpin)
    isconnected(outpin, inpin) && (@warn "$outpin and $inpin are already connected."; return)
    link = Link{promote_type(eltype(outpin), eltype(inpin))}()
    bind(link, outpin)
    bind(link, inpin)
    return link
end
connect(outpins::AbstractVector{<:Outpin}, inpins::AbstractVector{<:Inpin}) = connect.(outpins, inpins)
connect(outpins, inpins) = connect([outpins...], [inpins...])

"""
    disconnect(link1::Link, link2::Link)

Disconnects `link1` and `link2`. The order of arguments is not important. See also: [`connect`](@ref)
"""
function disconnect(outpin::Outpin, inpin::Inpin)
    deleteat!(outpin.links, findall(link -> link == inpin.link, outpin.links))
    inpin.link = Link{eltype(inpin)}()
end
disconnect(outpins::AbstractVector{<:Outpin}, inpins::AbstractVector{<:Inpin}) = (disconnect.(outpins, inpins); nothing)
disconnect(outpins, inpins) = disconnect([outpins...], [inpins...])


"""
    isconnected(link1, link2)

Returns `true` if `link1` is connected to `link2`. The order of the arguments are not important.
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
