# This file includes interpolant for interplation of sampled inputs. 

"""
    $TYPEDEF 

Constructs a linnear interpolant that interpolates between the poinsts `(tinit, coefinit)` and `(tfinal, coeffinal)`.

# Fields 

    $TYPEDFIELDS
"""
mutable struct Interpolant{TMB, INB, ITP}
    "Buffer to record time"
    timebuf::TMB
    "Buffer to record data"
    databuf::INB 
    "Internal interpolating function"
    itp::ITP
    function Interpolant(nt::Int, nd::Int) 
        timebuf = Buffer(nt) 
        databuf = nd == 1 ? Buffer(nt) : Buffer(nd, nt)
        itp = [interpolation(zeros(1), zeros(1)) for i in 1 : nd]
        new{typeof(timebuf), typeof(databuf), typeof(itp)}(timebuf, databuf, itp)
    end
end 

show(io::IO, interpolant::Interpolant) = print(io, "Interpolant(timebuf:$(interpolant.timebuf), ", 
    "databuf:$(interpolant.databuf), itp:$(interpolant.itp))")

# Callling interpolant.
# Syntax for u(t).
(interp::Interpolant)(t) = ndims(buf) == 1 ? interp.itp(t) : map(f -> f(t), interp.itp)

# Syntax for u[idx](t)
getindex(interp::Interpolant, idx::Vararg{Int, N}) where N = interp.itp[idx...]


# Update of interpolant. That is, reinterpolation. 
"""
    $SIGNATURES

Updates `interpolant` using the data in `timebuf` and `databuf` of `interpolant`.
"""
update!(interpolant::Interpolant{T1, <:AbstractVector, T2}) where {T1,T2} = interpolant.itp[1] = _update!(interpolant)
update!(interpolant::Interpolant{T1, <:AbstractMatrix, T2}) where {T1,T2} = interpolant.itp = _update!(interpolant)
_update!(interpolant) = interpolation(content(interpolant.timebuf, flip=true), content(interpolant.databuf, flip=true))

interpolation(tt, uu::AbstractMatrix) = map(row -> interpolation(tt, row), eachrow(uu))
interpolation(tt, uu::AbstractVector) = CubicSplineInterpolation(getranges(tt, uu)...; extrapolation_bc=Line())

function getranges(tt, uu)
    length(tt) < 2 && return (range(tt[1], length=2, step=eps()), range(uu[1], length=2, step=eps()))
    return range(tt[1], tt[end], length=length(tt)), uu
end
