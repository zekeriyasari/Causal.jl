# This file includes interpolant for interplation of sampled inputs. 

"""
    Interpolant(tinit, tfinal, coefinit, coeffinal)

Constructs a linnear interpolant that interpolates between the poinsts `(tinit, coefinit)` and `(tfinal, coeffinal)`.
"""
mutable struct Interpolant{TMB, INB, ITP}
    timebuf::TMB
    databuf::INB 
    itp::ITP
end 

function Interpolant(nt::Int, nd::Int)
    timebuf = Buffer(nt)
    databuf = nd == 1 ? Buffer(nt) : Buffer(nd, nt)
    Interpolant(timebuf, databuf, interpolation(zeros(1), zeros(nd, 1)))
end

show(io::IO, interpolant::Interpolant)= print(io, "Interpolant(timebuf:$(interpolant.timebuf), ", 
    "databuf:$(interpolant.databuf), itp:$(interpolant.itp))")

# Callling interpolant.
(interpolant::Interpolant)(t) = interpolant.itp(t)
getindex(interpolant::Interpolant, idx::Int) = interpolant.itp[idx]

function interpolation(tt::AbstractVector, uu::AbstractVector)
    if length(tt) < 2 
        trange = range(tt[1], length=2, step=eps())
        uvector = range(uu[1], length=2, step=eps())
    else 
        trange = range(tt[1], tt[end], length=length(tt))
        uvector = uu
    end
    [CubicSplineInterpolation(trange, uvector, extrapolation_bc=Line())]
end
interpolation(tt::AbstractVector, uu::AbstractMatrix) = vcat(map(row -> interpolation(tt, row), eachrow(uu))...)

function update!(interpolant::Interpolant)
    tt = content(interpolant.timebuf, flip=true)
    uu = content(interpolant.databuf, flip=true)
    interpolant.itp = interpolation(tt, uu)
end
