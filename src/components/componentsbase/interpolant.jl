# This file includes interpolant for interplation of sampled inputs. 

export Interpolant

"""
    $(TYPEDEF) 

Interpolant that interpolates the data in `timebuf` and `databuf`

# Fields 

    $(TYPEDFIELDS)
"""
mutable struct Interpolant{T1, T2, T3}
    timebuf::T1 
    databuf::T2
    itp::T3
    function Interpolant(timebuf, databuf) 
        T1, T2 = eltype(timebuf), eltype(databuf) 
        t = range(zero(T1), one(T1), length=3)
        itp = if T2 <: Real 
            u = zeros(T2, 3)
            CubicSplineInterpolation(t, u, extrapolation_bc=Line())
        else
            u = fill(zeros(eltype(T2), 3), length(databuf))
            map(row -> CubicSplineInterpolation(t, row, extrapolation_bc=Line()), eachcol(hcat(u...)))
        end
        new{typeof(timebuf), typeof(databuf), typeof(itp)}(timebuf, databuf, itp)
    end 
end 


# Syntax for u(t) 
(interp::Interpolant)(t) = interp.itp(t)

# Syntax for u[idx](t)
getindex(interp::Interpolant, idx::Vararg{Int, N}) where N = interp.itp[idx...]

const ScalarInterpolant = Interpolant{T1, T2, T3} where {T1, T2, T3<:AbstractInterpolation}
const VectorInterpolant = Interpolant{T1, T2, T3} where {T1, T2, T3<:AbstractVector{<:AbstractInterpolation}}

torange(val) = range(val[1], val[end], length=length(val))

"""
    $(SIGNATURES)

Updates `interpolant` using the data in `timebuf` and `databuf` of `interpolant`.
"""
update!(interp::Interpolant) = (interp.itp = getinterp(interp); interp)
getinterp(interp::ScalarInterpolant) = 
    CubicSplineInterpolation(torange(content(interp.timebuf)), content(interp.databuf), extrapolation_bc=Line()) 
getinterp(interp::VectorInterpolant) = map(eachrow(hcat(content(interp.databuf)...))) do row 
        CubicSplineInterpolation(torange(content(interp.timebuf)), row, extrapolation_bc=Line())
    end
