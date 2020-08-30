# This file includes interpolant for interplation of sampled inputs. 

export Interpolant

mutable struct Interpolant{TT, DT, IT}
    timebuf::TT
    databuf::DT
    itp::IT
    function Interpolant(timebuf, databuf)
        tt = content(timebuf) 
        uu = content(databuf)
        itp = eltype(uu) <: AbstractVector ? vectorinterp(tt, uu) : scalarinterp(tt, uu)
        new{typeof(timebuf), typeof(databuf), typeof(itp)}(timebuf, databuf, itp)
    end
end  

const ScalarInterpolant = Interpolant{T1, T2, T3} where {T1, T2, T3<:AbstractInterpolation}
const VectorInterpolant = Interpolant{T1, T2, T3} where {T1, T2, T3<:AbstractVector{<:AbstractInterpolation}}

scalarinterp(tt, uu) = CubicSplineInterpolation(getranges(tt, uu)...; extrapolation_bc=Line())
vectorinterp(tt, uu) = (@show uu; map(row -> scalarinterp(tt, row), eachrow(hcat(uu...))))

update!(interp::ScalarInterpolant) = 
    (interp.itp = scalarinterp(content(interp.timebuf),content(interp.databuf)); interp)
update!(interp::VectorInterpolant) = 
    (interp.itp = vectorinterp(content(interp.timebuf), content(interp.databuf)); interp)

function getranges(tt, uu)
    length(tt) < 2 && return (range(tt[1], length=2, step=eps()), range(uu[1], length=2, step=eps()))
    return range(tt[1], tt[end], length=length(tt)), uu
end


# """
#     $(TYPEDEF)

# # Fields 

#     $(TYPEDFIELDS)
# """
# mutable struct Interpolant{TT, DT, IT}
#     timebuf::TT
#     databuf::DT 
#     itp::IT
#     function Interpolant(timebuf, databuf) 
#         isempty(timebuf) && error("$timebuf is empty")
#         isempty(databuf) && error("$databuf is empty")
#         itp = getinterp(content(timebuf), content(databuf))
#         new{typeof(timebuf), typeof(databuf), typeof(itp)}(timebuf, databuf, itp)
#     end
# end 

# getinterp(tt, uu::AbstractVector{T}) where T <: Union{Missing, <:Real} = 
#     CubicSplineInterpolation(getranges(tt, uu)...; extrapolation_bc=Line())
# getinterp(tt, uu::AbstractVector{T}) where T<:Union{Missing, <:AbstractVector} = 
#     map(row -> getinterp(tt, row), eachrow(uu))

# show(io::IO, interpolant::Interpolant) = print(io, "Interpolant(timebuf:$(interpolant.timebuf), ", 
#     "databuf:$(interpolant.databuf), itp:$(interpolant.itp))")

# # Callling interpolant.
# """
#     $(SIGNATURES)

# Returns interpolant fucntion at index `idx`.
# """
# getindex(interpolant::Interpolant, idx::Int) = interpolant.itp[idx]

# # Update of interpolant. That is, reinterpolation. 
# """
#     $(SIGNATURES)

# Updates `interpolant` using the data in `timebuf` and `databuf` of `interpolant`.
# """
# update!(interpolant::Interpolant{T1, <:AbstractVector, T2}) where {T1,T2} = interpolant.itp[1] = _update!(interpolant)
# update!(interpolant::Interpolant{T1, <:AbstractMatrix, T2}) where {T1,T2} = interpolant.itp = _update!(interpolant)
# _update!(interpolant) = getinterp(content(interpolant.timebuf, flip=true), content(interpolant.databuf, flip=true))

