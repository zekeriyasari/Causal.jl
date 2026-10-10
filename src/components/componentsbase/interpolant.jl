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
    "Number of valid samples, retained across cyclic buffer wraps"
    nvalid::Int
    function Interpolant(nt::Int, nd::Int) 
        timebuf = Buffer(nt) 
        databuf = nd == 1 ? Buffer(nt) : Buffer(nd, nt)
        itp = [interpolation(zeros(1), zeros(1)) for i in 1 : nd]
        new{typeof(timebuf), typeof(databuf), typeof(itp)}(timebuf, databuf, itp, 0)
    end
end 

show(io::IO, interpolant::Interpolant) = print(io, "Interpolant(timebuf:$(interpolant.timebuf), ", 
    "databuf:$(interpolant.databuf), itp:$(interpolant.itp))")

# Callling interpolant.
# Syntax for u(t).
(interp::Interpolant)(t) = ndims(interp.databuf) == 1 ? interp.itp[1](t) : map(f -> f(t), interp.itp)

# Syntax for u[idx](t)
getindex(interp::Interpolant, idx::Vararg{Int, N}) where N = interp.itp[idx...]


# Update of interpolant. That is, reinterpolation. 
"""
    $SIGNATURES

Updates `interpolant` using the data in `timebuf` and `databuf` of `interpolant`.
"""
update!(interpolant::Interpolant{T1, <:AbstractVector, T2}) where {T1,T2} = interpolant.itp[1] = _update!(interpolant)
update!(interpolant::Interpolant{T1, <:AbstractMatrix, T2}) where {T1,T2} = interpolant.itp = _update!(interpolant)
function _update!(interpolant)
    timebuf, databuf = interpolant.timebuf, interpolant.databuf
    # Buffer.index is a chunk counter and wraps. Previously content() then
    # discarded valid historical taps, periodically reducing to one sample.
    interpolant.nvalid = max(interpolant.nvalid,
        isfull(timebuf) ? datalength(timebuf) : timebuf.index - 1)
    n = interpolant.nvalid
    tt = reverse(outbuf(timebuf)[1:n])
    uu = ndims(databuf) == 1 ? reverse(outbuf(databuf)[1:n]) :
                              reverse(outbuf(databuf)[:,1:n], dims=2)
    interpolation(tt, uu)
end

interpolation(tt, uu::AbstractMatrix) = map(row -> interpolation(tt, row), eachrow(uu))
interpolation(tt, uu::AbstractVector) = CubicSplineInterpolation(getranges(tt, uu)...; extrapolation_bc=Line())

function getranges(tt, uu)
    # One available sample represents a constant, not an invented unit ramp.
    # A finite time spacing avoids roundoff-amplified derivatives at startup.
    length(tt) < 2 && return (range(tt[1], length=2, step=1.0), [uu[1], uu[1]])
    return range(tt[1], tt[end], length=length(tt)), uu
end
